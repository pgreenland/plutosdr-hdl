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

proc init {cellpath otherInfo} {
  set ip [get_bd_cells $cellpath]

  bd::mark_propagate_override $ip \
    "ASYNC_CLK"

}

proc detect_async_clk { cellpath ip param_name clk_a clk_b } {
  set param_src [get_property "CONFIG.$param_name.VALUE_SRC" $ip]
  if {[string equal $param_src "USER"]} {
    return;
  }

  set clk_domain_a [get_property CONFIG.CLK_DOMAIN $clk_a]
  set clk_domain_b [get_property CONFIG.CLK_DOMAIN $clk_b]
  set clk_freq_a [get_property CONFIG.FREQ_HZ $clk_a]
  set clk_freq_b [get_property CONFIG.FREQ_HZ $clk_b]
  set clk_phase_a [get_property CONFIG.PHASE $clk_a]
  set clk_phase_b [get_property CONFIG.PHASE $clk_b]

  # Only mark it as sync if we can make sure that it is sync, if the
  # relationship of the clocks is unknown mark it as async
  if {$clk_domain_a != {} && $clk_domain_b != {} && \
    $clk_domain_a == $clk_domain_b && $clk_freq_a == $clk_freq_b && \
    $clk_phase_a == $clk_phase_b} {
    set clk_async 0
  } else {
    set clk_async 1
  }

  set_property "CONFIG.$param_name" $clk_async $ip

}

proc propagate {cellpath otherinfo} {
  set ip [get_bd_cells $cellpath]

  set link_clk [get_bd_pins "$ip/clk"]
  set device_clk [get_bd_pins "$ip/device_clk"]

  detect_async_clk $cellpath $ip "ASYNC_CLK" $link_clk $device_clk
}

