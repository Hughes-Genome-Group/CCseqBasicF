#!/bin/bash

##########################################################################
# Copyright 2017, Jelena Telenius (jelena.telenius@imm.ox.ac.uk)         #
#                                                                        #
# This file is part of CCseqBasic5 .                                     #
#                                                                        #
# CCseqBasic5 is free software: you can redistribute it and/or modify    #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# CCseqBasic5 is distributed in the hope that it will be useful,         #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with CCseqBasic5.  If not, see <http://www.gnu.org/licenses/>.   #
##########################################################################

printToLogFile(){
   
# Needs this to be set :
# printThis="" 

echo ""
echo -e "${printThis}"
echo ""

echo "" >> "/dev/stderr"
echo -e "${printThis}" >> "/dev/stderr"
echo "" >> "/dev/stderr"
    
}

printToTrimmingLogFile(){
   
# Needs this to be set :
# printThis="" 

echo ""
echo -e "${printThis}"
echo ""

echo "" >> "read_trimming.log"
echo -e "${printThis}" >> "read_trimming.log"
echo "" >> "read_trimming.log"
    
}

doInputFileTesting(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""    
    
    if [ ! -r "${testedFile}" ] || [ ! -e "${testedFile}" ] || [ ! -f "${testedFile}" ] || [ ! -s "${testedFile}" ]; then
      echo "Input file not found or empty file : ${testedFile}" >> "/dev/stderr"
      echo "EXITING!!" >> "/dev/stderr"
      exit 1
    fi
}

doTempFileTesting(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""    
    
    if [ ! -r "${testedFile}" ] || [ ! -e "${testedFile}" ] || [ ! -f "${testedFile}" ] || [ ! -s "${testedFile}" ]; then
      echo "Temporary file not found or empty file : ${testedFile}" >> "/dev/stderr"
      echo "EXITING!!" >> "/dev/stderr"
      exit 1
    fi
}

fileTesting(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""    
    
    if [ ! -s "${testedFile}" ] || [ ! -r "${testedFile}" ] || [ ! -f "${testedFile}" ] ; then
      echo "File not found or cannot be read or empty file : ${testedFile}" >> "/dev/stderr"
      echo "EXITING!!" >> "/dev/stderr"
      exit 1
    fi
}

doQuotaTesting(){
    
    echo
    if [ $( pwd | grep -c '^/t1-data1/' ) -ne 0 ]; then
        getquota-t1data1 2>>/dev/null
    else
        getquota 2>>/dev/null
    fi
        
    echo
    echo "Disk usage for THIS RUN - at the moment :"
    du -sh ${dirForQuotaAsking}
    echo
    
}