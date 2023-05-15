## ***************************************************************************
## ***************************************************************************
## Copyright 2014 - 2023 (c) Analog Devices, Inc. All rights reserved.
##
## In this HDL repository, there are many different and unique modules, consisting
## of various HDL (Verilog or VHDL) components. The individual modules are
## developed independently, and may be accompanied by separate and unique license
## terms.
##
## The user should read each of these license terms, and understand the
## freedoms and responsibilities that he or she has by using this source/core.
##
## This core is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
## A PARTICULAR PURPOSE.
##
## Redistribution and use of source or resulting binaries, with or without modification
## of this file, are permitted under one of the following two license terms:
##
##   1. The GNU General Public License version 2 as published by the
##      Free Software Foundation, which can be found in the top level directory
##      of this repository (LICENSE_GPL2), and also online at:
##      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
##
## OR
##
##   2. An ADI specific BSD license, which can be found in the top level directory
##      of this repository (LICENSE_ADIBSD), and also on-line at:
##      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
##      This will allow to generate bit files and not release the source code,
##      as long as it attaches to an ADI device.
##
## ***************************************************************************
## ***************************************************************************

proc spi_engine_create {{name "spi_engine"} {data_width 32} {async_spi_clk 1} {num_cs 1} {num_sdi 1} {num_sdo 1} {sdi_delay 0} {echo_sclk 0}} {

  puts "echo_sclk: $echo_sclk"

  create_bd_cell -type hier $name
  current_bd_instance /$name

  if {$async_spi_clk == 1} {
    create_bd_pin -dir I -type clk spi_clk
  }
  if {$echo_sclk == 1} {
    create_bd_pin -dir I -type clk echo_sclk
  }
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst resetn
  create_bd_pin -dir I trigger
  create_bd_pin -dir O irq
  create_bd_intf_pin -mode Master -vlnv analog.com:interface:spi_master_rtl:1.0 m_spi
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_sample

  set execution "${name}_execution"
  set axi_regmap "${name}_axi_regmap"
  set offload "${name}_offload"
  set interconnect "${name}_interconnect"

  ad_ip_instance spi_engine_execution $execution
  ad_ip_parameter $execution CONFIG.DATA_WIDTH $data_width
  ad_ip_parameter $execution CONFIG.NUM_OF_CS $num_cs
  ad_ip_parameter $execution CONFIG.NUM_OF_SDI $num_sdi
  ad_ip_parameter $execution CONFIG.SDO_DEFAULT 1
  ad_ip_parameter $execution CONFIG.SDI_DELAY $sdi_delay
  ad_ip_parameter $execution CONFIG.ECHO_SCLK $echo_sclk

  ad_ip_instance axi_spi_engine $axi_regmap
  ad_ip_parameter $axi_regmap CONFIG.DATA_WIDTH $data_width
  ad_ip_parameter $axi_regmap CONFIG.NUM_OFFLOAD 1
  ad_ip_parameter $axi_regmap CONFIG.NUM_OF_SDI $num_sdi
  ad_ip_parameter $axi_regmap CONFIG.ASYNC_SPI_CLK $async_spi_clk

  ad_ip_instance spi_engine_offload $offload
  ad_ip_parameter $offload CONFIG.DATA_WIDTH $data_width
  ad_ip_parameter $offload CONFIG.ASYNC_SPI_CLK $async_spi_clk
  ad_ip_parameter $offload CONFIG.NUM_OF_SDI $num_sdi

  ad_ip_instance spi_engine_interconnect $interconnect
  ad_ip_parameter $interconnect CONFIG.DATA_WIDTH $data_width
  ad_ip_parameter $interconnect CONFIG.NUM_OF_SDI $num_sdi

  ad_connect $axi_regmap/spi_engine_offload_ctrl0 $offload/spi_engine_offload_ctrl
  ad_connect $offload/spi_engine_ctrl $interconnect/s0_ctrl
  ad_connect $axi_regmap/spi_engine_ctrl $interconnect/s1_ctrl
  ad_connect $interconnect/m_ctrl $execution/ctrl
  ad_connect $offload/offload_sdi m_axis_sample
  ad_connect $offload/trigger trigger

  ad_connect $execution/spi m_spi

  ad_connect clk $axi_regmap/s_axi_aclk

  if {$async_spi_clk == 1} {
    ad_connect spi_clk $offload/spi_clk
    ad_connect spi_clk $offload/ctrl_clk
    ad_connect spi_clk $execution/clk
    ad_connect spi_clk $axi_regmap/spi_clk
    ad_connect spi_clk $interconnect/clk
  } else {
    ad_connect clk $offload/spi_clk
    ad_connect clk $offload/ctrl_clk
    ad_connect clk $execution/clk
    ad_connect clk $axi_regmap/spi_clk
    ad_connect clk $interconnect/clk
  }

  if {$echo_sclk == 1} {
    ad_connect echo_sclk $execution/echo_sclk
  }

  ad_connect $axi_regmap/spi_resetn $offload/spi_resetn
  ad_connect $axi_regmap/spi_resetn $execution/resetn
  ad_connect $axi_regmap/spi_resetn $interconnect/resetn

  ad_connect resetn $axi_regmap/s_axi_aresetn
  ad_connect irq $axi_regmap/irq

  current_bd_instance /
}
