// ***************************************************************************
// ***************************************************************************
// Copyright 2015 - 2022 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module dmac_sg #(
  parameter DMA_AXI_ADDR_WIDTH = 32,
  parameter DMA_DATA_WIDTH = 64,
  parameter DMA_LENGTH_WIDTH = 24,
  parameter AXI_LENGTH_WIDTH = 8,
  parameter BYTES_PER_BEAT_WIDTH_DEST = 3,
  parameter BYTES_PER_BEAT_WIDTH_SRC = 3,
  parameter BYTES_PER_BEAT_WIDTH_SG = 3
) (
  input m_axi_aclk,
  input m_axi_aresetn,

  input req_enable,

  input req_in_valid,
  output req_in_ready,

  output req_out_valid,
  input req_out_ready,

  output resp_out_eot,
  input resp_in_valid,

  input [DMA_AXI_ADDR_WIDTH-1:BYTES_PER_BEAT_WIDTH_SG] req_desc_address,

  output [DMA_AXI_ADDR_WIDTH-1:BYTES_PER_BEAT_WIDTH_DEST] out_dest_address,
  output [DMA_AXI_ADDR_WIDTH-1:BYTES_PER_BEAT_WIDTH_SRC] out_src_address,
  output [DMA_LENGTH_WIDTH-1:0] out_x_length,
  output [DMA_LENGTH_WIDTH-1:0] out_y_length,
  output [DMA_LENGTH_WIDTH-1:0] out_dest_stride,
  output [DMA_LENGTH_WIDTH-1:0] out_src_stride,
  output [31:0] resp_out_id,

  // Read address
  input                            m_axi_arready,
  output                           m_axi_arvalid,
  output [DMA_AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
  output [AXI_LENGTH_WIDTH-1:0]    m_axi_arlen,
  output [ 2:0]                    m_axi_arsize,
  output [ 1:0]                    m_axi_arburst,
  output [ 2:0]                    m_axi_arprot,
  output [ 3:0]                    m_axi_arcache,

  // Read data and response
  input  [DMA_DATA_WIDTH-1:0]      m_axi_rdata,
  output                           m_axi_rready,
  input                            m_axi_rvalid,
  input  [ 1:0]                    m_axi_rresp
);

  localparam STATE_IDLE = 0;
  localparam STATE_SEND_ADDR = 1;
  localparam STATE_RECV_DESC = 2;
  localparam STATE_DESC_READY = 3;

  localparam FLAG_IS_LAST_HWDESC = 1 << 0;
  localparam FLAG_EOT_IRQ = 1 << 1;

  reg [31:BYTES_PER_BEAT_WIDTH_DEST] dest_addr;
  reg [31:BYTES_PER_BEAT_WIDTH_SRC] src_addr;
  reg [31:BYTES_PER_BEAT_WIDTH_SG] next_desc_addr;
  reg [DMA_LENGTH_WIDTH-1:0] x_length;
  reg [DMA_LENGTH_WIDTH-1:0] y_length;
  reg [DMA_LENGTH_WIDTH-1:0] dest_stride;
  reg [DMA_LENGTH_WIDTH-1:0] src_stride;

  reg [1:0] hwdesc_state;
  reg [2:0] hwdesc_counter;
  reg [31:0] hwdesc_flags;
  reg [31:0] hwdesc_id;

  assign out_dest_address = dest_addr;
  assign out_src_address = src_addr;
  assign out_x_length = x_length;
  assign out_y_length = y_length;
  assign out_dest_stride = dest_stride;
  assign out_src_stride = src_stride;

  wire fifo_in_valid;
  wire fifo_in_ready;
  wire fifo_out_valid;
  wire fifo_out_ready;
  wire fetch_valid;
  wire fetch_ready;
  wire [32:0] fifo_out_data;

  assign req_in_ready = hwdesc_state == STATE_IDLE ? 1'b1 : 1'b0;
  assign fetch_valid = hwdesc_state == STATE_DESC_READY ? 1'b1 : 1'b0;
  assign m_axi_arvalid = hwdesc_state == STATE_SEND_ADDR ? 1'b1 : 1'b0;
  assign m_axi_rready = hwdesc_state == STATE_RECV_DESC ? 1'b1 : 1'b0;

  assign m_axi_arsize  = 3'h3;
  assign m_axi_arburst = 2'h1;
  assign m_axi_arprot  = 3'h0;
  assign m_axi_arcache = 4'h3;
  assign m_axi_arlen   = 'h5;
  assign m_axi_araddr  = {next_desc_addr, {BYTES_PER_BEAT_WIDTH_SG{1'b0}}};

  always @(posedge m_axi_aclk) begin
    if (m_axi_aresetn == 1'b0) begin
      hwdesc_counter <= 'h0;
    end else if (m_axi_rvalid) begin
      hwdesc_counter <= hwdesc_counter + 1'b1;
    end else if (hwdesc_state == STATE_DESC_READY) begin
      hwdesc_counter <= 'h0;
    end
  end

  always @(posedge m_axi_aclk) begin
    if (m_axi_aresetn == 1'b0) begin
      hwdesc_flags <= 'h00;
      hwdesc_id <= 'h00;
      dest_addr <= 'h00;
      src_addr <= 'h00;
      next_desc_addr <= 'h00;
      y_length <= 'h00;
      x_length <= 'h00;
      src_stride <= 'h00;
      dest_stride <= 'h00;
    end else begin
      if (hwdesc_state == STATE_IDLE) begin
        next_desc_addr <= req_desc_address;
      end
      if (m_axi_rvalid) begin
        case (hwdesc_counter)
        0: begin
          hwdesc_id <= m_axi_rdata[63:32];
          hwdesc_flags <= m_axi_rdata[31:0];
          end
        1: dest_addr <= m_axi_rdata[31:BYTES_PER_BEAT_WIDTH_DEST];
        2: src_addr <= m_axi_rdata[31:BYTES_PER_BEAT_WIDTH_SRC];
        3: next_desc_addr <= m_axi_rdata[31:BYTES_PER_BEAT_WIDTH_SG];
        4: begin
          x_length <= m_axi_rdata[63:32];
          y_length <= m_axi_rdata[31:0];
          end
        5: begin
          dest_stride <= m_axi_rdata[63:32];
          src_stride <= m_axi_rdata[31:0];
          end
        endcase
      end
    end
  end

  always @(posedge m_axi_aclk) begin
    if (m_axi_aresetn == 1'b0) begin
      hwdesc_state <= STATE_IDLE;
    end else begin
      case (hwdesc_state)
        STATE_IDLE: begin
          if (req_in_valid == 1'b1 && req_enable == 1'b1) begin
            hwdesc_state <= STATE_SEND_ADDR;
          end
          end

        STATE_SEND_ADDR: begin
          if (m_axi_arready) begin
            hwdesc_state <= STATE_RECV_DESC;
          end
          end

        STATE_RECV_DESC: begin
          if (m_axi_rvalid == 1'b1 && hwdesc_counter == 5) begin
            hwdesc_state <= STATE_DESC_READY;
          end
          end

        STATE_DESC_READY: begin
          if (req_enable == 1'b0) begin
              hwdesc_state <= STATE_IDLE;
          end else if (fetch_ready == 1'b1) begin
            if (hwdesc_flags & FLAG_IS_LAST_HWDESC) begin
              hwdesc_state <= STATE_IDLE;
            end else begin
              hwdesc_state <= STATE_SEND_ADDR;
            end
          end
          end
      endcase
    end
  end

  wire fifo_splitter_aresetn;
  assign fifo_splitter_aresetn = m_axi_aresetn & (req_enable | ~req_in_ready);

  splitter #(
    .NUM_M(2)
  ) i_req_splitter (
    .clk(m_axi_aclk),
    .resetn(fifo_splitter_aresetn),
    .s_valid(fetch_valid),
    .s_ready(fetch_ready),
    .m_valid({
      req_out_valid,
      fifo_in_valid
    }),
    .m_ready({
      req_out_ready,
      fifo_in_ready
    }));

  wire [32:0] fifo_in_data;
  assign fifo_in_data = {hwdesc_flags & FLAG_EOT_IRQ ? 1'b1 : 1'b0, hwdesc_id};

  util_axis_fifo #(
    .DATA_WIDTH(33),
    .ADDRESS_WIDTH(3),
    .ASYNC_CLK(0)
  ) i_fifo (
    .s_axis_aclk(m_axi_aclk),
    .s_axis_aresetn(fifo_splitter_aresetn),

    .s_axis_valid(fifo_in_valid),
    .s_axis_ready(fifo_in_ready),
    .s_axis_data(fifo_in_data),

    .m_axis_aclk(m_axi_aclk),
    .m_axis_aresetn(fifo_splitter_aresetn),

    .m_axis_valid(fifo_out_valid),
    .m_axis_ready(fifo_out_ready),
    .m_axis_data({resp_out_eot, resp_out_id}));

  assign fifo_out_ready = resp_in_valid;

endmodule
