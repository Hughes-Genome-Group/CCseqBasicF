#!/bin/bash

##########################################################################
# Copyright 2017, Jelena Telenius (jelena.telenius@imm.ox.ac.uk)         #
#                                                                        #
# This file is part of CCseqBasic5 .                                     #
#                                                                        #
# CCseqBasic5 is free software: you can redistribute it and/or modify    #
# it under the terms of the MIT license.
#
#
#                                                                        #
# CCseqBasic5 is distributed in the hope that it will be useful,         #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# MIT license for more details.
#                                                                        #
# You should have received a copy of the MIT license
# along with CCseqBasic5.  
##########################################################################

setMparameter(){
   
mParameter=""

if [ "${CAPITAL_M}" -eq 0 ] ; then
    mParameter="-m ${LOWERCASE_M}"
else
    mParameter="-M ${CAPITAL_M}"
fi 
    
}

setParameters(){

#----------------------------------------------
# Listing current limitations, exiting if needed :

if [ "${LOWERCASE_M}" -ne 0 ] && [ "${CAPITAL_M}" -ne 0 ];
then
    printThis="Both -m and -M parameters cannot be set at the same time\nEXITING"
    printToLogFile
  exit 1 
fi

#---------------------------------------------

if [ "${LOWERCASE_V}" -ne -1 ] && [ "${bowtieMismatchBehavior}" != "" ]
then
    printThis="Bowtie1 does not allow setting -v with any other mismatch-reporting altering parameters ( --seedmms --seedlen --maqerr ) \nUse only -v, or (any) combination of --seedmms --seedlen --maqerr\nEXITING"
    printToLogFile
  exit 1
fi

if [ "${bowtieMismatchBehavior}" != "" ]
then
    otherBowtie1Parameters="${otherBowtie1Parameters} ${bowtieMismatchBehavior}"
fi

if [ "${LOWERCASE_V}" -ne -1 ]
then
    otherBowtie1Parameters="${otherBowtieParameters} -v ${LOWERCASE_V}"
fi

#----------------------------------------------
#Setting the m and M parameters..

if [ "${LOWERCASE_M}" -ne 0 ] ;
then
   CAPITAL_M=0 
fi

if [ "${CAPITAL_M}" -ne 0 ];
then
   LOWERCASE_M=0
fi

if [ "${LOWERCASE_M}" -eq 0 ] && [ "${CAPITAL_M}" -eq 0 ];
then
    LOWERCASE_M=2
fi

#------------------------------------------------
# Custom adapter sequences..

if [ "${ADA31}" != "no"  ] || [ "${ADA32}" != "no" ] || [ "${ADA51}" != "no" ] || [ "${ADA52}" != "no" ] 
    then
    CUSTOMAD=1
fi

}

