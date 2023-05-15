#!/bin/bash
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

# Depending on simulator, search for errors or 'SUCCESS' keyword in specific log
if [[ "$SIMULATOR" == "modelsim" ]]; then
	ERRS=`grep -i -e '# Error ' -e '# Fatal' -e '# Failed' -C 10 ${NAME}_modelsim.log`
	SUCCESS=`grep 'SUCCESS' ${NAME}_${SIMULATOR}.log`
elif [[ "$SIMULATOR" == "xsim" ]]; then
	ERRS=`grep -v ^# ${NAME}_xvlog.log | grep -w -i -e error -e fatal -e fatal_error -e failed -C 10`
	ERRS=$ERRS`grep -v ^# ${NAME}_xelab.log | grep -w -i -e error -e fatal -e fatal_error -e failed -C 10`
	ERRS=$ERRS`grep -v ^# ${NAME}_xsim.log | grep -w -i -e error -e fatal -e fatal_error -e failed -C 10`
	SUCCESS=`grep 'SUCCESS' ${NAME}_xsim.log`
else
	echo "XML file is generated only for 'modelsim' and 'xsim' simulators."
	echo "Check that variable SIMULATOR is exported and is set to one of those."
fi

# If DURATION is not defined, try to extract it from log file. If it's not found, just use 0
if [[ -z ${DURATION+x} ]]; then
	DURATION=$(grep -i 'elapsed' ${NAME}_${SIMULATOR}.log | cut -d ' ' -f '10')
	if [[ -z "$DURATION" ]]; then DURATION="0";fi
fi

#Generate xml file
xmlFile="${NAME}.xml"
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > $xmlFile
echo -e "<testsuite>" >> $xmlFile
echo -e "\t<testcase name=\"${NAME}\" time=\"${DURATION}\" classname=\"component_tb\">" >> $xmlFile
if [[ "$ERRS" ]]; then
	#replace < with &lt; and > with &gt; in ERRS to not broke created xml
	ERRS=$(echo $ERRS | sed 's/</&lt;/g' | sed 's/>/&gt;/g')
	echo -e "\t\t<failure>\n\"$ERRS\"\n\t\t</failure>" >> $xmlFile
elif [[ "$SUCCESS" ]]; then
	echo -e "\t\t<passed/>" >> $xmlFile
else	#There is no error or 'SUCCESS' keyword in log file - set result to 'Skipped'
	echo -e "<skipped>" >> $xmlFile
	echo -e "\tThe log file does not contain any errors or 'SUCCESS' keyword." >> $xmlFile
	echo -e "\tLog file was not created properly or the testbench is not automated" >> $xmlFile
	echo -e "</skipped>" >> $xmlFile
fi
echo -e "\t</testcase>" >> $xmlFile
echo "</testsuite>" >> $xmlFile
