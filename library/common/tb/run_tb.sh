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

export NAME=`basename $0`

# MODE not defined or defined to something else than 'batch'
if [[ -z ${MODE+x} ]] || [[ ! "$MODE" =~ "batch" ]]; then MODE="gui";fi
MODE="-"${MODE##*-} #remove any eventual extra dashes

case "$SIMULATOR" in
	modelsim)
  		# ModelSim flow
  		vlib work
  		vlog ${SOURCE} || exit 1
		vsim ${NAME} -do "add log /* -r; run -a" $MODE -logfile ${NAME}_modelsim.log || exit 1
		;;

	xsim)
		# XSim flow
		xvlog -log ${NAME}_xvlog.log --sourcelibdir . ${SOURCE} || exit 1
		xelab -log ${NAME}_xelab.log -debug all ${NAME} || exit 1
		if [[ "$MODE" == "-gui" ]]; then
			echo "log_wave -r *" > xsim_gui_cmd.tcl
			echo "run all" >> xsim_gui_cmd.tcl
			xsim work.${NAME} -gui -tclbatch xsim_gui_cmd.tcl -log ${NAME}_xsim.log
		else
			xsim work.${NAME} -R -log ${NAME}_xsim.log
		fi
		;;

	xcelium)
		# Xcelium flow
		xmvlog -NOWARN NONPRT ${SOURCE} || exit 1
		xmelab -access +rc ${NAME}
		xmsim ${NAME} -gui || exit 1
		;;

	*)
		#Icarus flow is the default
		mkdir -p run
		mkdir -p vcd
		iverilog -o run/run_${NAME} -I.. ${SOURCE} $1 || exit 1
		cd vcd
		../run/run_${NAME}
		;;
esac

