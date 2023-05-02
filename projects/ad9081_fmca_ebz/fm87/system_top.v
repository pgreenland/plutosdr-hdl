// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2023 (c) Analog Devices, Inc. All rights reserved.
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

module system_top #(
  // Dummy parameters to workaround critical warning
  parameter RX_LANE_RATE       = 10,
  parameter TX_LANE_RATE       = 10,
  parameter RX_JESD_M          = 8,
  parameter RX_JESD_L          = 4,
  parameter RX_JESD_S          = 1,
  parameter RX_JESD_NP         = 16,
  parameter RX_NUM_LINKS       = 1,
  parameter TX_JESD_M          = 8,
  parameter TX_JESD_L          = 4,
  parameter TX_JESD_S          = 1,
  parameter TX_JESD_NP         = 16,
  parameter TX_NUM_LINKS       = 1,
  parameter RX_KS_PER_CHANNEL  = 32,
  parameter TX_KS_PER_CHANNEL  = 32
) (

  // clock and resets
  input                   sys_clk,
  input                   hps_io_ref_clk,
  // input                refclk_bti, // additional refclk_bti to preserve Etile XCVR
  input                   sys_resetn,

  // hps-emif
  input                   emif_hps_pll_ref_clk,
  output                  emif_hps_mem_clk_p,
  output                  emif_hps_mem_clk_n,
  output  [16:0]          emif_hps_mem_a,
  output  [1:0]           emif_hps_mem_ba,
  output                  emif_hps_mem_bg,
  output                  emif_hps_mem_cke,
  output                  emif_hps_mem_cs_n,
  output                  emif_hps_mem_odt,
  output                  emif_hps_mem_reset_n,
  output                  emif_hps_mem_act_n,
  output                  emif_hps_mem_par,
  input                   emif_hps_mem_alert_n,
  inout   [8:0]           emif_hps_mem_dqs_p,
  inout   [8:0]           emif_hps_mem_dqs_n,
  inout   [8:0]           emif_hps_mem_dbi_n,
  inout   [71:0]          emif_hps_mem_dq,
  input                   emif_hps_oct_rzq,

  // hps-emac
  input                   hps_emac_rxclk,
  input                   hps_emac_rxctl,
  input   [ 3:0]          hps_emac_rxd,
  output                  hps_emac_txclk,       //TODO: may need to change RMII TX CLK to be input instead, check
  output                  hps_emac_txctl,
  output  [ 3:0]          hps_emac_txd,
  output                  hps_emac_mdc,
  inout                   hps_emac_mdio,

  // hps-sdio
  output                  hps_sdio_clk,
  inout                   hps_sdio_cmd,
  inout   [ 3:0]          hps_sdio_d,

  // hps-usb
  input                   hps_usb_clk,
  input                   hps_usb_dir,
  input                   hps_usb_nxt,
  output                  hps_usb_stp,
  inout   [ 7:0]          hps_usb_d,

  // hps-uart
  input                   hps_uart_rx,
  output                  hps_uart_tx,

  // hps-i2c
  inout                   hps_i2c_sda,
  inout                   hps_i2c_scl,

  // hps-jtag
  input                   hps_jtag_tck,
  input                   hps_jtag_tms,
  output                  hps_jtag_tdo,
  input                   hps_jtag_tdi,

  // hps-gpio
  inout   [ 6:0]          hps_gpio

  // FMC HPC IOs

  // lane interface
  input                   clkin6,
  input                   fpga_refclk_in,
  input   [RX_JESD_L-1:0] rx_data,
  output  [TX_JESD_L-1:0] tx_data,
  input                   fpga_syncin_0,
  inout                   fpga_syncin_1_n,
  inout                   fpga_syncin_1_p,
  output                  fpga_syncout_0,
  inout                   fpga_syncout_1_n,
  inout                   fpga_syncout_1_p,
  input                   sysref2,

  // spi
  output                  spi0_csb,
  input                   spi0_miso,
  output                  spi0_mosi,
  output                  spi0_sclk,
  output                  spi1_csb,
  output                  spi1_sclk,
  inout                   spi1_sdio,

  // gpio
  input   [1:0]           agc0,
  input   [1:0]           agc1,
  input   [1:0]           agc2,
  input   [1:0]           agc3,
  inout   [10:0]          gpio,
  inout                   hmc_gpio1,
  output                  hmc_sync,
  input   [1:0]           irqb,
  output                  rstb,
  output  [1:0]           rxen,
  output  [1:0]           txen);

  wire          ninit_done;
  wire          sys_reset_n;
  wire          h2f_reset;
  wire  [43:0]  stm_hw_events;
  wire  [31:0]  f2h_irq1;

  wire          hps_mem_cal_success;
  wire          hps_mem_cal_fail;
  wire  [ 9:0]  gpio_bd_i;
  wire  [ 7:0]  gpio_bd_o;
  wire  [63:0]  gpio_i;
  wire  [63:0]  gpio_o;
  wire  [ 7:0]  spi_csn_s;

  // assignmnets

  assign spi0_csb = spi_csn_s[0];
  assign spi1_csb = spi_csn_s[1];

  assign spi0_sclk = spi_clk;
  assign spi1_sclk = spi_clk;

  assign spi0_mosi = spi_mosi;

  ad_3w_spi #(
    .NUM_OF_SLAVES(1)
  ) i_spi_hmc (
    .spi_csn (spi_csn_s[1]),
    .spi_clk (spi_clk),
    .spi_mosi (spi_mosi),
    .spi_miso (spi_hmc_miso),
    .spi_sdio (spi1_sdio),
    .spi_dir ());

  assign spi_miso = ~spi_csn_s[0] ? spi0_miso :
                    ~spi_csn_s[1] ? spi_hmc_miso :
                    1'b0;

  // assignments
  assign gpio_i[63:32] = gpio_o[63:32];

  // board stuff
  assign gpio_i[31:19] = gpio_o[31:19];

  assign gpio_i[18:18] = hps_mem_cal_success;
  assign gpio_i[17:17] = hps_mem_cal_fail;
  assign gpio_i[16:15] = gpio_bd_i[9:8]; // buttons
  assign gpio_i[14: 7] = gpio_bd_i[7:0]; // dipsws
  assign gpio_i[ 6: 0] = gpio_o[6:0];    // leds
  assign gpio_bd_o     = gpio_o[6:0];

  assign f2h_irq1      = 32'b0;
  assign stm_hw_events = 44'b0;
  assign sys_reset_n   = sys_resetn & ~h2f_reset & ~ninit_done;

  // instantiations

  system_bd i_system_bd (
    .sys_clk_clk                               (sys_clk),
    .sys_hps_io_hps_osc_clk                    (hps_io_ref_clk),

    .sys_rst_reset_n                           (sys_reset_n),
   // .src_prb_rst_sources_source              (1'b1), // temporary disable
    .rst_ninit_done_ninit_done                 (ninit_done),

    .sys_gpio_led_export                       (gpio_bd_o),      // leds
    .sys_gpio_button_export                    (gpio_bd_i[9:8]), // buttons
    .sys_gpio_dipsw_export                     (gpio_bd_i[7:0]), // dipsws
    .sys_gpio_bd_in_port                       (gpio_i[31:0]),
    .sys_gpio_bd_out_port                      (gpio_o[31:0]),
    .sys_gpio_in_export                        (gpio_i[63:32]),
    .sys_gpio_out_export                       (gpio_o[63:32]),

    .emif_hps_mem_mem_ck                       (emif_hps_mem_clk_p),
    .emif_hps_mem_mem_ck_n                     (emif_hps_mem_clk_n),
    .emif_hps_mem_mem_a                        (emif_hps_mem_a),
    .emif_hps_mem_mem_act_n                    (emif_hps_mem_act_n),
    .emif_hps_mem_mem_ba                       (emif_hps_mem_ba),
    .emif_hps_mem_mem_bg                       (emif_hps_mem_bg),
    .emif_hps_mem_mem_cke                      (emif_hps_mem_cke),
    .emif_hps_mem_mem_cs_n                     (emif_hps_mem_cs_n),
    .emif_hps_mem_mem_odt                      (emif_hps_mem_odt),
    .emif_hps_mem_mem_reset_n                  (emif_hps_mem_reset_n),
    .emif_hps_mem_mem_par                      (emif_hps_mem_par),
    .emif_hps_mem_mem_alert_n                  (emif_hps_mem_alert_n),
    .emif_hps_mem_mem_dqs                      (emif_hps_mem_dqs_p),
    .emif_hps_mem_mem_dqs_n                    (emif_hps_mem_dqs_n),
    .emif_hps_mem_mem_dq                       (emif_hps_mem_dq),
    .emif_hps_mem_mem_dbi_n                    (emif_hps_mem_dbi_n),
    .emif_hps_oct_oct_rzqin                    (emif_hps_oct_rzq),
    .emif_hps_pll_ref_clk_clk                  (emif_hps_pll_ref_clk),
 // .local_cal_success_local_cal_success       (hps_mem_cal_success),
 // .local_cal_fail_local_cal_fail             (hps_mem_cal_fail),

    .sys_hps_io_EMAC0_TX_CLK                   (hps_emac_txclk),
    .sys_hps_io_EMAC0_TX_CTL                   (hps_emac_txctl),
    .sys_hps_io_EMAC0_TXD0                     (hps_emac_txd[0]),
    .sys_hps_io_EMAC0_TXD1                     (hps_emac_txd[1]),
    .sys_hps_io_EMAC0_TXD2                     (hps_emac_txd[2]),
    .sys_hps_io_EMAC0_TXD3                     (hps_emac_txd[3]),
    .sys_hps_io_EMAC0_RX_CLK                   (hps_emac_rxclk),
    .sys_hps_io_EMAC0_RX_CTL                   (hps_emac_rxctl),
    .sys_hps_io_EMAC0_RXD0                     (hps_emac_rxd[0]),
    .sys_hps_io_EMAC0_RXD1                     (hps_emac_rxd[1]),
    .sys_hps_io_EMAC0_RXD2                     (hps_emac_rxd[2]),
    .sys_hps_io_EMAC0_RXD3                     (hps_emac_rxd[3]),
    .sys_hps_io_EMAC0_MDIO                     (hps_emac_mdio),
    .sys_hps_io_EMAC0_MDC                      (hps_emac_mdc),

    .sys_hps_io_SDMMC_CCLK                     (hps_sdio_clk),
    .sys_hps_io_SDMMC_CMD                      (hps_sdio_cmd),
    .sys_hps_io_SDMMC_D0                       (hps_sdio_d[0]),
    .sys_hps_io_SDMMC_D1                       (hps_sdio_d[1]),
    .sys_hps_io_SDMMC_D2                       (hps_sdio_d[2]),
    .sys_hps_io_SDMMC_D3                       (hps_sdio_d[3]),

    .sys_hps_io_USB0_CLK                       (hps_usb_clk),
    .sys_hps_io_USB0_STP                       (hps_usb_stp),
    .sys_hps_io_USB0_DIR                       (hps_usb_dir),
    .sys_hps_io_USB0_NXT                       (hps_usb_nxt),
    .sys_hps_io_USB0_DATA0                     (hps_usb_d[0]),
    .sys_hps_io_USB0_DATA1                     (hps_usb_d[1]),
    .sys_hps_io_USB0_DATA2                     (hps_usb_d[2]),
    .sys_hps_io_USB0_DATA3                     (hps_usb_d[3]),
    .sys_hps_io_USB0_DATA4                     (hps_usb_d[4]),
    .sys_hps_io_USB0_DATA5                     (hps_usb_d[5]),
    .sys_hps_io_USB0_DATA6                     (hps_usb_d[6]),
    .sys_hps_io_USB0_DATA7                     (hps_usb_d[7]),

    .sys_hps_io_UART0_RX                       (hps_uart_rx),
    .sys_hps_io_UART0_TX                       (hps_uart_tx),

    .sys_hps_io_I2C1_SDA                       (hps_i2c_sda),
    .sys_hps_io_I2C1_SCL                       (hps_i2c_scl),

    .sys_hps_io_jtag_tck                       (hps_jtag_tck),
    .sys_hps_io_jtag_tms                       (hps_jtag_tms),
    .sys_hps_io_jtag_tdo                       (hps_jtag_tdo),
    .sys_hps_io_jtag_tdi                       (hps_jtag_tdi),
    //Terminate the CS_JTAG.
    .sys_hps_h2f_cs_ntrst                      (1'b1),
    .sys_hps_h2f_cs_tck                        (1'b1),
    .sys_hps_h2f_cs_tdi                        (1'b1),
    .sys_hps_h2f_cs_tdo                        (),
    .sys_hps_h2f_cs_tdoen                      (),
    .sys_hps_h2f_cs_tms                        (1'b1),

    .sys_hps_io_gpio1_io0                      (hps_gpio[0]),
    .sys_hps_io_gpio1_io1                      (hps_gpio[1]),
    .sys_hps_io_gpio1_io4                      (hps_gpio[2]),
    .sys_hps_io_gpio1_io5                      (hps_gpio[3]),
    .sys_hps_io_gpio1_io19                     (hps_gpio[4]),
    .sys_hps_io_gpio1_io20                     (hps_gpio[5]),
    .sys_hps_io_gpio1_io21                     (hps_gpio[6]),

    .h2f_reset_reset                           (h2f_reset),

    .sys_hps_f2h_stm_hw_events_stm_hwevents    (stm_hw_events),
    .f2h_irq1_irq                              (f2h_irq1)
    // FMC HPC
    .sys_spi_MISO                              (spi_miso),
    .sys_spi_MOSI                              (spi_mosi),
    .sys_spi_SCLK                              (spi_clk),
    .sys_spi_SS_n                              (spi_csn_s),

    .tx_serial_data_tx_serial_data (tx_data[TX_JESD_L-1:0]),
    .tx_ref_clk_clk (refclk_fgt_2),
    .tx_sync_export (fpga_syncin_0),
    .tx_sysref_export (sysref2),
    .tx_device_clk_clk (clkin6),
    .rx_serial_data_rx_serial_data (rx_data[RX_JESD_L-1:0]),
    .rx_ref_clk_clk (refclk_fgt_2),
    .rx_sync_export (fpga_syncout_0),
    .rx_sysref_export (sysref2),
    .rx_device_clk_clk (clkin6),
    .ref_clk_in_in_refclk_fgt_2 (fpga_refclk_in),
    .ref_clk_fgt_2_clk (refclk_fgt_2)
   // .ref_clk_clk (ref_clk),
   // .ref_clk_in_in_refclk_fgt_2 (refclk_fgt_2)
  );

endmodule
