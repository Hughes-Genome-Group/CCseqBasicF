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

runFlash(){
    
    echo
    echo "Running flash with parameters :"
    echo " m (minimum overlap) : ${flashOverlap}"
    echo " x (sum-of-mismatches/overlap-lenght) : ${flashErrorTolerance}"
    echo " p phred score min (33 or 64) : ${intQuals}"
    echo
    printThis="flash --interleaved-output -p ${intQuals} -m ${flashOverlap} -x ${flashErrorTolerance} READ1.fastq READ2.fastq > flashing.log"
    printToLogFile
    
    # flash --interleaved-output -p "${intQuals}" READ1.fastq READ2.fastq > flashing.log
    flash --interleaved-output -p "${intQuals}" -m "${flashOverlap}" -x "${flashErrorTolerance}" READ1.fastq READ2.fastq > flashing.log
    
    ls | grep out*fastq
    
    # This outputs these files :
    # flashing.log  FLASHED.fastq  out.hist  out.histogram  NONFLASHED.fastq  o

    echo "Read counts after flash :"
    
    flashedCount=0
    nonflashedCount=0
    
    if [ -s "out.extendedFrags.fastq" ] ; then
        flashedCount=$(( $( grep -c "" out.extendedFrags.fastq )/4 ))
    fi
    if [ -s "out.notCombined.fastq" ] ; then
        nonflashedCount=$(( $( grep -c "" out.notCombined.fastq )/4 ))
    fi
    
    mv -f out.extendedFrags.fastq FLASHED.fastq
    mv -f out.notCombined.fastq NONFLASHED.fastq
    
    echo "FLASHED.fastq (count of read pairs combined in flash) : ${flashedCount}"
    echo "NONFLASHED.fastq (not extendable via flash) : ${nonflashedCount}"
    
}

runCCanalyser(){
    
################################################################
# Running CAPTURE-C analyser for the aligned file..

#sampleForCCanalyser="RAW_${Sample}"
#samForCCanalyser="Combined_reads_REdig.sam"
#runDir=$( pwd )
#samDirForCCanalyser=${runDir}
#publicPathForCCanalyser="${PublicPath}/RAW"
#JamesUrlForCCanalyser="${JamesUrl}/RAW"


printThis="Running CAPTURE-C analyser for the aligned file.."
printToLogFile

testedFile="${OligoFile}"
doTempFileTesting

mkdir -p "${publicPathForCCanalyser}"

printThis="perl ${RunScriptsPath}/${CCscriptname} -f ${samDirForCCanalyser}/${samForCCanalyser} -o ${OligoFile} -r ${fullPathDpnGenome} --pf ${publicPathForCCanalyser} --pu ${JamesUrlForCCanalyser} -s ${sampleForCCanalyser} --genome ${GENOME} --ucscsizes ${ucscBuild} -w ${WINDOW} -i ${INCREMENT} --flashed ${FLASHED} --duplfilter ${DUPLFILTER} ${otherParameters}"
printToLogFile

echo "-f Input filename "
echo "-r Restriction coordinates filename "
echo "-o Oligonucleotide position filename "
echo "--CCversion CF3 or CF4 or CF5 (which version of the duplicate filtering we will perform)"
echo "--pf Your public folder"
echo "--pu Your public url"
echo "-s Sample name (and the name of the folder it goes into)"
echo "-w Window size (default = 2kb)"
echo "-i Window increment (default = 200bp)"
echo "--dump Print file of unaligned reads (sam format)"
echo "--snp Force all capture points to contain a particular SNP"
echo "--limit Limit the analysis to the first n reads of the file"
echo "--genome Specify the genome (mm9 / hg18)"
echo "--ucscsizes Chromosome sizes file path"
echo "--globin Combines the two captures from the gene duplicates (HbA1 and HbA2)"
echo "--flashed	1 or 0 (are the reads in input sam combined via flash or not ? - run out.extended with 1 and out.not_combined with 0)"
echo "--duplfilter 1 or 0 (will the reads be duplicate filtered)\n"
echo "--parp Filter artificial chromosome chrPARP out before visualisation"
echo "--stringent enforces additional stringency - forces all reported subfragments to be unique"
echo "--stranded To replicate the strand-specific (i.e. wrong) duplicate filter of CB3a/CC3 and CB4a/CC4"


runDir=$( pwd )

# Copy used oligo file for archiving purposes..
cp ${OligoFile} usedOligoFile.txt

# remove parameter file from possible earlier run..
rm -f parameters_for_normalisation.log

perl ${RunScriptsPath}/${CCscriptname} --CCversion "${CCversion}" -f "${samDirForCCanalyser}/${samForCCanalyser}" -o "${OligoFile}" -r "${fullPathDpnGenome}" --pf "${publicPathForCCanalyser}" --pu "${JamesUrlForCCanalyser}" -s "${sampleForCCanalyser}" --genome "${GENOME}" --ucscsizes "${ucscBuild}" -w "${WINDOW}" -i "${INCREMENT}" --flashed "${FLASHED}" --duplfilter "${DUPLFILTER}" ${otherParameters}

echo "Contents of run folder :"
ls -lht

echo
echo "Contents of CCanalyser output folder ( ${sampleForCCanalyser}_${CCversion} ) "
ls -lht ${sampleForCCanalyser}_${CCversion}

echo
echo "Counts of output files - by file type :"

count=$( ls -1 ${publicPathForCCanalyser} | grep -c '.bw' )
echo
echo "${count} bigwig files (should be x2 the amount of oligos, if all had captures)"

count=$( ls -1 ${sampleForCCanalyser}_${CCversion} | grep -c '.wig' )
echo
echo "${count} wig files (should be x2 the amount of oligos, if all had captures)"

count=$( ls -1 ${sampleForCCanalyser}_${CCversion} | grep -c '.gff')
echo
echo "${count} gff files (should be x1 the amount of oligos, if all had captures)"

echo
echo "Output log files :"
ls -1 ${sampleForCCanalyser}_${CCversion} | grep '.txt'

echo
echo "Bed files :"
ls -1 ${sampleForCCanalyser}_${CCversion} | grep '.bed'

echo
echo "Sam files :"
ls -1 ${sampleForCCanalyser}_${CCversion} | grep '.sam'

echo
echo "Fastq files :"
ls -1 ${sampleForCCanalyser}_${CCversion} | grep '.fastq'   
    
}

