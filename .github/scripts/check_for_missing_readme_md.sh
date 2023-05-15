#!/bin/sh
#
## ***************************************************************************
## ***************************************************************************
## Copyright 2022 - 2023 (c) Analog Devices, Inc. All rights reserved.
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
#
# The purpose of this script:
# Ensure there are README.md (case insensitive name) files in all the project directories

set -e
#set -x

fail=0

check_string() {
	needle=$1
	if [ "$(grep "${needle}" $file | wc -l)" -eq "0" ] ; then
		echo In $file: missing \"${needle}\"
		fail=1
	else
		if [ "$(grep "${needle}" $file | sed -e "s/${needle}//g" -e "s/ //g" | wc -c)" -lt "8" ] ; then
			 echo In $file: missing link for \"${needle}\"
			 fail=1
		fi
	fi
}

MISSING=$(find projects/ -mindepth 1 -maxdepth 1 \( -path projects/common -o -path projects/scripts \) -prune -o -type d '!' -exec test -e "{}/README.md" ';' -print)
if [ "$(echo ${MISSING} | wc -c)" -gt "1" ] ; then
	echo "Missing README.md files in ${MISSING}"
	fail=1
fi

for file in $(find projects/ -mindepth 2 -maxdepth 2 -iname README.md)
do
	check_string "Board Product Page"
	check_string "* Parts"
	check_string "* Project Doc"
	check_string "* HDL Doc"
	check_string "* Linux Drivers"

	if [ "$(grep "([[:space:]]*)" $file | wc -l)" -gt "0" ] ; then
		echo "In $file: missing link; found ()"
		fail=1
	fi
	if [ "$(grep https://wiki.analog.com/resources/tools-software/linux-drivers-all $file | wc -l)" -gt "0" ] ; then
		echo "In $file: do not link to https://wiki.analog.com/resources/tools-software/linux-drivers-all"
		fail=1
	fi
	if [ "$(grep https://wiki.analog.com/linux $file | wc -l)" -gt "0" ] ; then
		echo "In $file: do not link to https://wiki.analog.com/linux"
		fail=1
	fi
done

if [ "${fail}" -eq "1" ] ; then
	exit 1
fi
