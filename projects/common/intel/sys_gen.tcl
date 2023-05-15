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

# globals

set_global_assignment -name OPTIMIZATION_MODE "AGGRESSIVE PERFORMANCE"
set_global_assignment -name SYNCHRONIZER_IDENTIFICATION AUTO
set_global_assignment -name ENABLE_ADVANCED_IO_TIMING ON
set_global_assignment -name USE_TIMEQUEST_TIMING_ANALYZER ON
set_global_assignment -name TIMEQUEST_DO_REPORT_TIMING ON
set_global_assignment -name TIMEQUEST_DO_CCPP_REMOVAL ON
set_global_assignment -name TIMEQUEST_REPORT_SCRIPT $ad_hdl_dir/projects/scripts/adi_tquest.tcl
set_global_assignment -name ON_CHIP_BITSTREAM_DECOMPRESSION OFF

# version check

set REQUIRED_QUARTUS_VERSION "16.1.2"
set QUARTUS_VERSION [lindex $quartus(version) 1]
if {[string compare $QUARTUS_VERSION $REQUIRED_QUARTUS_VERSION] != 0} {
  puts -nonewline "Critical Warning: quartus version mismatch; "
  puts -nonewline "expected $REQUIRED_QUARTUS_VERSION, "
  puts -nonewline "got $QUARTUS_VERSION.\n"
}

# library paths
if {[info exists ::env(ADI_GHDL_DIR)]} {
  set ad_lib_folders "$ad_hdl_dir/library/**/*;$ad_ghdl_dir/library/**/*"
} else {
  set ad_lib_folders "$ad_hdl_dir/library/**/*"
}

set_user_option -name USER_IP_SEARCH_PATHS $ad_lib_folders
set_global_assignment -name IP_SEARCH_PATHS $ad_lib_folders

# qsys-script is a crippled tool, so work around is generate a run-time one

set mmu_enabled 1
if [info exists ::env(NIOS_MMU_ENABLED)] {
  set mmu_enabled $::env(NIOS_MMU_ENABLED)
}

set QFILE [open "system_qsys_script.tcl" "w"]
puts $QFILE "set mmu_enabled $mmu_enabled"
puts $QFILE "set ad_hdl_dir $ad_hdl_dir"
if {[info exists ::env(ADI_GHDL_DIR)]} {
  puts $QFILE "set ad_ghdl_dir $ad_ghdl_dir"
}
puts $QFILE "source system_qsys.tcl"
puts $QFILE "set_interconnect_requirement {\$system} {qsys_mm.clockCrossingAdapter} {FIFO}"
puts $QFILE "set_interconnect_requirement {\$system} {qsys_mm.maxAdditionalLatency} {2}"
puts $QFILE "save_system {system_bd.qsys}"
close $QFILE

exec -ignorestderr $quartus(quartus_rootpath)/sopc_builder/bin/qsys-script \
  --script=system_qsys_script.tcl

# remove altshift_taps

set_instance_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF -to * -entity up_xfer_cntrl
set_instance_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF -to * -entity up_xfer_status
set_instance_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF -to * -entity up_clock_mon
set_instance_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF -to * -entity ad_rst
set_instance_assignment -name QII_AUTO_PACKED_REGISTERS OFF -to * -entity up_xfer_cntrl
set_instance_assignment -name QII_AUTO_PACKED_REGISTERS OFF -to * -entity up_xfer_status
set_instance_assignment -name QII_AUTO_PACKED_REGISTERS OFF -to * -entity up_clock_mon
set_instance_assignment -name QII_AUTO_PACKED_REGISTERS OFF -to * -entity ad_rst

