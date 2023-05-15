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

  bd::mark_propagate_only $ip \
    "AXI_ADDR_WIDTH"
}

# Executed when you close the config window
proc post_config_ip {cellpath otherinfo} {
  set ip [get_bd_cells $cellpath]

  # Update AXI interface properties according to configuration
  set axi_protocol [get_property "CONFIG.AXI_PROTOCOL" $ip]
  set data_width [get_property "CONFIG.AXI_DATA_WIDTH" $ip]

  set src_fifo_size [get_property "CONFIG.SRC_FIFO_SIZE" $ip]
  set dst_fifo_size [get_property "CONFIG.DST_FIFO_SIZE" $ip]

  if {$axi_protocol == 0} {
    set axi_protocol_str "AXI4"
    set max_beats_per_burst 256
  } else {
    set axi_protocol_str "AXI3"
    set max_beats_per_burst 16
  }

  set num_m [get_property "CONFIG.NUM_M" $ip]
  for {set idx 0} {$idx < $num_m} {incr idx} {

    set intf [get_bd_intf_pins [format "%s/MAXI_%d" $cellpath $idx]]

    set_property CONFIG.PROTOCOL $axi_protocol_str $intf
    set_property CONFIG.MAX_BURST_LENGTH $max_beats_per_burst $intf

    set_property CONFIG.NUM_WRITE_OUTSTANDING $src_fifo_size $intf
    set_property CONFIG.NUM_READ_OUTSTANDING  $dst_fifo_size $intf

  }

  # For multi master configurations (e.g.HBM) the AXIS data widths must match
  if { $num_m > 1} {
    set src_width [get_property "CONFIG.SRC_DATA_WIDTH" $ip]
    set dst_width [get_property "CONFIG.DST_DATA_WIDTH" $ip]
    if {$src_width != $dst_width} {
      bd::send_msg -of $cellpath -type ERROR -msg_id 1 -text ": For multi AXI master configuration the Source AXIS interface width ($src_width) must match the Destination AXIS interface width ($dst_width)  ."
    } else {
      # AXIS Data widths divided by number of masters must be >= 8 and power of 2
      set bits_per_master [expr $src_width/$num_m]
      if {$bits_per_master < 8} {
        bd::send_msg -of $cellpath -type ERROR -msg_id 2 -text ": Number of AXI masters ($num_m) too high. AXIS data widths divided by number of masters ($src_width / $num_m = $bits_per_master) must be >= 8 ."
      }
    }
  }

}

proc log2 {x} {
  return [tcl::mathfunc::int [tcl::mathfunc::ceil [expr [tcl::mathfunc::log $x] / [tcl::mathfunc::log 2]]]]
}

# Executed when the block design is validated
proc propagate {cellpath otherinfo} {
  set ip [get_bd_cells $cellpath]

}

proc post_propagate {cellpath otherinfo} {
	set ip [get_bd_cells $cellpath]

  #Check address space
  set length_width [get_property "CONFIG.LENGTH_WIDTH" $ip]
  set axi_addr_width [get_property "CONFIG.AXI_ADDR_WIDTH" $ip]
  set ddr_base_adddress [get_property "CONFIG.DDR_BASE_ADDDRESS" $ip]
  set hbm_segment_index [get_property "CONFIG.HBM_SEGMENT_INDEX" $ip]
  set mem_type [get_property "CONFIG.MEM_TYPE" $ip]
  if {$mem_type == 1} {
    set addr_width [log2 [expr $ddr_base_adddress + 2 ** $length_width - 1]]
  } else {
    # assumption: 1 segmetn is 256MB
    set addr_width [log2 [expr $hbm_segment_index * 256 * 1024 * 1024 + 2 ** $length_width - 1]]
  }

  set_property "CONFIG.AXI_ADDR_WIDTH" $addr_width $ip
  bd::send_msg -of $cellpath -type INFO -msg_id 2 -text ": AXI Address Width  set to $addr_width"

}
