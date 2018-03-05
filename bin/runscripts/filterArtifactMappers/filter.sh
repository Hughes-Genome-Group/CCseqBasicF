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


# This code does the following :

# 1) generates blat filter files for each oligo
# 2) filters the gff files and sam files (these are the CCanalyser output)
#    2a) ploidy filter
#    2b) blat filter
# 3) runs the DESeq differential analysis for each sample (?)

GENOME="UNDEFINED"
oligofile="UNDEFINED"
recoordinatefile="UNDEFINED"
datafolder="UNDEFINED"
# dataprefix="UNDEFINED"
dataprefixFLASHED="UNDEFINED"
dataprefixNONFLASHED="UNDEFINED"

#------------------------------------------

version="VS104"

parameterfile="UNDEFINED"
ploidyfilter=1
outputToRunfolder=0
outputfolder="UNDEFINED"

extend=20000

pipelinecall=0

#   -tileSize=N sets the size of match that triggers an alignment.  
#               Usually between 8 and 12
#               Default is 11 for DNA and 5 for protein.
#   -stepSize=N spacing between tiles. Default is tileSize.
#   -oneOff=N   If set to 1 this allows one mismatch in tile and still
#               triggers an alignments.  Default is 0.
#   -minScore=N sets minimum score.  This is the matches minus the 
#               mismatches minus some sort of gap penalty.  Default is 30
#   -maxIntron=N  Sets maximum intron size. Default is 750000
#   -repMatch=N sets the number of repetitions of a tile allowed before
#               it is marked as overused.  Typically this is 256 for tileSize
#               12, 1024 for tile size 11, 4096 for tile size 10.
#               Default is 1024.  Typically only comes into play with makeOoc.
#               Also affected by stepSize. When stepSize is halved repMatch is
#               doubled to compensate.

# Setting the minIdentity to 70, as this is to find DUPLICATED regions. the default for finding these has been traditionally set to 70.
minIdentity=70 # Jon default 0 (used in CC4 pipe i.e filter version VS103 up to 08Sep2016) - James used minIdentity=70 (this was the setting in CC2 and CC3 - i.e filter versions VS101 and VS102)
repMatch=999999 # Jon default

# User flags, with defaults
stepSize=5 # Jon default - James used blat default, which is "tileSize", in this case thus 11 (this was the setting in CC2 and CC3 - i.e filter versions VS101 and VS102)
tileSize=11 # Jon, James default
minScore=10 # Jon default 10, Jon before2016 default 20 (used in CC4 i.e filter version VS103 pipe up to 08Sep2016), James used minScore=30 (this was the setting in CC2 and CC3 - i.e filter versions VS101 and VS102)
maxIntron=4000 # blat default maxIntron=750000 (used in CC4 pipe i.e filter version VS103 up to 08Sep2016) - James used maxIntron=4000 (this was the setting in CC2 and CC3 - i.e filter versions VS101 and VS102)
oneOff=0 # allow 1 mismatch in tile (blat default = 0 - that is also CC3 and CC2 default)

# Whether we reuse blat results from earlier run ..
# Having this as "." will search from the run dir when blat is ran - so file will not be found, and thus BLAT will be ran normally.
reuseBLATpath="."


ploidyGFFoverlap(){
    echo "intersectappend.pl ${file} ${ploidyPath} PloidyRegion TRUE FALSE "
    echo "intersectappend.pl ${file} ${ploidyPath} PloidyRegion TRUE FALSE "  >> "/dev/stderr"    
    ${RunScriptsPath}/intersectappend.pl ${file} ${ploidyPath} PloidyRegion TRUE FALSE | sed 's/\s\.PloidyRegion/\tPloidyRegion/' > TEMP.txt
    mv -f TEMP.txt TEMPdir2/${newname}_PF.gff
}

blatGFFoverlap(){

    # If we have this oligo mentioned in the blat filter files ..
    if [ -s "${oligoname}_blat_blat_filter_extendedBy${extend}b.gff" ] ; then
        
        #intersectappend.pl <a gff3 file> <b gff3 file> <facet name> <return value true> <return value false>
        
            echo "intersectappend.pl ${file} ${oligoname}_blat_blat_filter_extendedBy${extend}b.gff BlatFilteredRegion TRUE FALSE "
            echo "intersectappend.pl ${file} ${oligoname}_blat_blat_filter_extendedBy${extend}b.gff BlatFilteredRegion TRUE FALSE "  >> "/dev/stderr"
        
        ${RunScriptsPath}/intersectappend.pl ${file} ${oligoname}_blat_blat_filter_extendedBy${extend}b.gff BlatFilteredRegion TRUE FALSE > ${outputfolder}/${newname}_BF.gff
        
    else
        echo "No blat filtering needed for this oligo ! - or this is globines combined track (or other track not listed in oligo file), for which this step is skipped.."
        cp ${file} ${outputfolder}/${newname}_noBF.gff
    fi    
    
}

filterSams()
{

for file in ${datafolder}/${dataprefix}_capture*.sam
do

# ${datafolder}
# 30ghC1_S6_REdig_CC2_Hba-1.sam
# 30ghC1_S6_REdig_CC2_Hba-2.sam

# ${outputfolder}
# 30ghC1_S6_REdig_CC2_Hba-1_forSAMfiltering.gff
# 30ghC1_S6_REdig_CC2_Hba-2_forSAMfiltering.gff

# Combined_reads_REdig_CC2_capture_Hba-1.sam
# Combined_reads_REdig_CC2_Hba-1.sam


    basename=$( echo $file | sed 's/.*'${dataprefix}'_capture_//' | sed 's/\.sam$//' )
    reporterfile=$( echo $file | sed 's/'${dataprefix}'_capture_/'${dataprefix}'_/' )
   
    samDataLineCount1000=$( cat ${file} | head -n 1000 | grep -cv "^@" )

    if [ "${samDataLineCount1000}" -ne "0" ]; then
        
           printThis="Filtering the reporter SAM file for ${basename} .."
           printToLogFile
        
            # Generating the bam file for the filtering..
            printThis="Generating the bam file for the filtering..\n samtools view -Sb -o TEMP.bam ${reporterfile}"
            printToLogFile
            samtools view -Sb -o TEMP.bam ${reporterfile}
            samDataLineCount=$( samtools view -c TEMP.bam )
            echo "Before filtering we have ${samDataLineCount} data lines in the SAM file"
            printToLogFile
            
            # Sorting the bam file for the filtering..
            printThis="Sorting the bam file for the filtering..\nsamtools sort -o TEMP_sorted.bam TEMP.bam; samtools index TEMP_sorted.bam"
            printToLogFile
            samtools sort -o TEMP_sorted.bam TEMP.bam
            mv -f TEMP_sorted.bam TEMP.bam
            samtools index TEMP.bam
    
    # Generating the heading (this could be under if clause - as now it is overwritten every round of the loop)
    samtools view -H -o TEMPheading_${dataprefix}.sam TEMP.bam

    # We check PLOIDY filter sam region count, and filter for ploidy..
    echo "${basename} ${dataprefix} - checking the need of filtering for PLOIDY regions.."
    
    if [ -s "${outputfolder}/${dataprefix}_${basename}_forPloidyFiltering.gff" ] ; then

        
        # Not filtering here - just counting how many regions.
        
        # Making bed file on the fly, from the gff file
        cut -f 1,4,5 "${outputfolder}/${dataprefix}_${basename}_forPloidyFiltering.gff" | awk '{print $1"\t"$2-1"\t"$3}' > TEMP.bed
        
        # Counting overlaps..
        overlaps=$( samtools view -c -L TEMP.bed TEMP.bam )
        
        echo "We will filter ${overlaps} sam fragments which overlap with the PLOIDY regions.."
    
    else
        
        echo "No ploidy filtering will be done."

    fi

    
    # We check BLAT filter sam region count.
    echo "${basename} ${dataprefix} - checking the need of filtering for BLAT regions.."
    
    if [ -s "${outputfolder}/${dataprefix}_${basename}_forBlatFiltering.gff" ] ; then       
        
        # Not filtering here - just counting how many regions.
        
        # Making bed file on the fly, from the gff file
        cut -f 1,4,5 "${outputfolder}/${dataprefix}_${basename}_forBlatFiltering.gff" | awk '{print $1"\t"$2-1"\t"$3}' > TEMP.bed
        
        # Counting overlaps..
        overlaps=$( samtools view -c -L TEMP.bed TEMP.bam )
        
        echo "We will filter ${overlaps} sam fragments which overlap with the BLAT-filter regions.."
    
    else
        
        echo "No BLAT-filtering will be done."
    
    fi

    # Now the filtering itself..
    
    echo
    
    if [ -s "${outputfolder}/${dataprefix}_${basename}_forBlatAndPloidyFiltering.gff" ] ; then
        echo "${basename} ${dataprefix} - filtering for PLOIDY and BLAT regions.."
        
        echo "bedtools intersect -v -abam ${file} -b ${outputfolder}/${dataprefix}_${basename}_forBlatAndPloidyFiltering.gff"
        bedtools intersect -v -abam TEMP.bam -b ${outputfolder}/${dataprefix}_${basename}_forBlatAndPloidyFiltering.gff > TEMPfiltered.bam
        mv -f TEMPfiltered.bam TEMP.bam
        
    fi

    
    # How many regions remain ?
    
    samfragments=$( samtools view -c TEMP.bam )
    
    printThis="After PLOIDY and BLAT filter we have ${samfragments} sam fragments left in our ${basename} ${dataprefix} reporter fragment file."
    printToLogFile

    samtools view -h -o ${outputfolder}/${basename}_filtered.sam TEMP.bam
    rm -f TEMP.bam*
    
    # Removing temporary files..
    
    rm -f ${outputfolder}/${dataprefix}_${basename}_forBlatAndPloidyFiltering.gff
    rm -f ${outputfolder}/${dataprefix}_${basename}_forBlatFiltering.gff
    rm -f ${outputfolder}/${dataprefix}_${basename}_forPloidyFiltering.gff
    rm -f TEMP.bed

    
    fi
    
    #--------------------------------------
    # Combining filtered SAM files for re-run in CCanalyser..
    
    printThis="Combining filtered reporter SAM file to the capture SAM for ${basename} ${dataprefix} .."
    printToLogFile    
    
    # All this stuff can be done via :
    # samtools sort  - sort REP and CAP files
    # samtools merge - merge REP and CAP sorted files
    # samtools sort -n  - sort by read name : ready for ccanalyser
    # However - now it is via unix commands for the time being.
    
    ls -lht ${outputfolder}/${basename}_filtered.sam
    ls -lht ${datafolder}/${dataprefix}_capture_${basename}.sam

    ls -lht ${outputfolder}/${basename}_filtered.sam >> "/dev/stderr"
    ls -lht ${datafolder}/${dataprefix}_capture_${basename}.sam >> "/dev/stderr"

    
    cat ${outputfolder}/${basename}_filtered.sam | grep -v "^@" > TEMP.sam
    cat ${datafolder}/${dataprefix}_capture_${basename}.sam  | grep -v "^@" >> TEMP.sam
    ls -lht | grep TEMP >> "/dev/stderr"

    # Sorting the files..

    cut -f 1 TEMP.sam | sed 's/:PE[12]:[0123456789][0123456789]*$//' > TEMP_sortcolumn.txt
    
    paste TEMP_sortcolumn.txt TEMP.sam | sort -k1,1 | cut -f 1 --complement > TEMP_sorted.sam
    ls -lht | grep TEMP >> "/dev/stderr"
    rm -f TEMP.sam TEMP_sortcolumn.txt
    
    # Adding to existing file..
    cat TEMP_sorted.sam >> TEMP_${dataprefix}_combined.sam
    ls -lht | grep TEMP >> "/dev/stderr"
    rm -f TEMP_sorted.sam

    ls -lht | grep combined >> "/dev/stderr"

done
    
}

#------------------------------------------

# Loading subroutines in ..

echo "Loading subroutines in .."

# /home/molhaem2/telenius/CCseqBasic/CCseqBasic4/bin/runscripts/filterArtifactMappers/filter.sh
CaptureTopPath="$( echo $0 | sed 's/\/bin\/runscripts\/filterArtifactMappers\/filter.sh//' )"

CapturePipePath="${CaptureTopPath}/bin/subroutines"

# TESTING file existence, log file output general messages
. ${CapturePipePath}/testers_and_loggers.sh

# SETTING THE GENOME BUILD PARAMETERS
. ${CapturePipePath}/genomeSetters.sh

# SETTING THE BLACKLIST GENOME LIST PARAMETERS
. ${CapturePipePath}/blacklistSetters.sh

#------------------------------------------

# From where to call the main scripts operating from the runscripts folder..

RunScriptsPath="${CaptureTopPath}/bin/runscripts"

#------------------------------------------

# From where to call the filtering scripts..
# (blacklisting regions with BLACKLIST pre-made region list, as well as on-the-fly BLAT-hit based "false positive" hits) 

CaptureFilterPath="${RunScriptsPath}/filterArtifactMappers"

#------------------------------------------

# From where to call the CONFIGURATION script..

confFolder="${CaptureTopPath}/conf"

#------------------------------------------

echo
echo "CaptureTopPath ${CaptureTopPath}"
echo "CapturePipePath ${CapturePipePath}"
echo "confFolder ${confFolder}"
echo "RunScriptsPath ${RunScriptsPath}"
echo "CaptureFilterPath ${CaptureFilterPath}"
echo

#------------------------------------------

# Calling in the CONFIGURATION script and its default setup :

echo "Calling in the conf/config.sh script and its default setup .."

CaptureDigestPath="NOT_IN_USE"
supportedGenomes=()
BOWTIE1=()
UCSC=()
genomesWhichHaveBlacklist=()
BLACKLIST=()

# . ${confFolder}/config.sh
. ${confFolder}/genomeBuildSetup.sh
. ${confFolder}/loadNeededTools.sh
. ${confFolder}/serverAddressAndPublicDiskSetup.sh

# setConfigLocations
setPathsForPipe
setGenomeLocations
setPublicLocations

echo 
echo "Supported genomes : "
for g in $( seq 0 $((${#supportedGenomes[@]}-1)) ); do echo -n "${supportedGenomes[$g]} "; done
echo 
echo

echo 
echo "Blacklist filtering available for these genomes : "
for g in $( seq 0 $((${#genomesWhichHaveBlacklist[@]}-1)) ); do echo -n "${genomesWhichHaveBlacklist[$g]} "; done
echo 
echo 


OPTS=`getopt -o p: --long parameterfile:,noploidyfilter,pipelinecall,extend:,stepSize:,tileSize:,minScore:,maxIntron:,oneOff:,reuseBLAT: -- "$@"`
if [ $? != 0 ]
then
    exit 1
fi

eval set -- "$OPTS"

while true ; do
    case "$1" in
        -p) parameterfile=$2 ; shift 2;;
        --parameterfile) parameterfile=$2 ; shift 2;;
        --pipelinecall) pipelinecall=1 ; shift 1;;
        --noploidyfilter) ploidyfilter=0 ; shift 1;;
        --extend) extend=$2 ; shift 2;;
        --stepSize) stepSize=$2 ; shift 2;;
        --tileSize) tileSize=$2 ; shift 2;;
        --minScore) minScore=$2 ; shift 2;;
        --maxIntron) maxIntron=$2 ; shift 2;;
        --oneOff) oneOff=$2 ; shift 2;;
        --reuseBLAT) reuseBLATpath=$2 ; shift 2;;
        
        --) shift; break;;
    esac
done


echo
echo "Filtering and normalising CCanalyser output .."
echo

if [ ! -s "${parameterfile}" ] ; then
    echo "Input parameter file ${parameterfile} not found or empty file" >> "/dev/stderr"
    echo "EXITING!!" >> "/dev/stderr"
    echo "Usage :"
    echo "norm.sh -p /path/to/parameters_for_normalisation.log"
    exit 1
fi

echo "blat -stepSize=${stepSize} -minScore=${minScore} -minIdentity=${minIdentity} -maxIntron=${maxIntron} -tileSize=${tileSize} -repMatch=${repMatch} -oneOff=${oneOff} ${GenomeFasta} ${file} ${basename}_blat.psl"
echo -n " -stepSize=${stepSize} -minScore=${minScore} -minIdentity=${minIdentity} -maxIntron=${maxIntron} -tileSize=${tileSize} -repMatch=${repMatch} -oneOff=${oneOff}" > blatParams.txt
blatparams=$(pwd)"/blatParams.txt"

# These will be listed in the parameters file :

#public_folder /public/telenius/capturetests/orig 
#oligo_filename /hts/data6/telenius/developmentAndTesting/captureVS1_VS2comparison_030915/oligos.txt
#sample orig
#restriction_enzyme_coords_file /hts/data2/jdavies/07mm9_dpn/mm9_dpnII_coordinates.txt 
#version CC2
#genome mm9
#globin 1 
#datafolder $output_path



GENOME=$( cat ${parameterfile} | grep "^genome\s" | sed 's/^genome\s\s*//' )
oligofile=$( cat ${parameterfile} | grep "^oligo_filename\s" | sed 's/^oligo_filename\s\s*//' )
recoordinatefile=$( cat ${parameterfile} | grep "^restriction_enzyme_coords_file\s" | sed 's/^restriction_enzyme_coords_file\s\s*//' )
datafolder=$( cat ${parameterfile} | grep "^datafolder\s" | sed 's/^datafolder\s\s*//' | sed 's/\s\s*$//' )

# dataprefix=$( cat ${parameterfile} | grep "^dataprefix\s" | sed 's/^dataprefix\s\s*//'  | sed 's/\s\s*$//' )
dataprefixFLASHED=$( cat ${parameterfile} | grep "^dataprefix_FLASHED\s" | sed 's/^dataprefix_FLASHED\s\s*//'  | sed 's/\s\s*$//' )
dataprefixNONFLASHED=$( cat ${parameterfile} | grep "^dataprefix_NONFLASHED\s" | sed 's/^dataprefix_NONFLASHED\s\s*//'  | sed 's/\s\s*$//' )

echo "GENOME ${GENOME}" >> parameters_norm.log
echo "oligofile ${oligofile}" >> parameters_norm.log
echo "recoordinatefile ${recoordinatefile}" >> parameters_norm.log
echo "dataprefixFLASHED ${dataprefixFLASHED}" >> parameters_norm.log
echo "dataprefixNONFLASHED ${dataprefixNONFLASHED}" >> parameters_norm.log


GenomeFasta="UNDEFINED"

setGenomeFasta

ucscBuild="UNDEFINED"

setUCSCgenomeSizes

# Setting run log output dir
# If this dir exists, taking safety copy of earlier..

if [ -d "BlatPloidyFilterRun" ] ; then
    datePrint=$(  date | sed 's/\s/_/g' | sed 's/://g' | sed 's/__//g' )
    mv -f BlatPloidyFilterRun old_BlatPloidyFilterRun_${datePrint}      
fi

mkdir BlatPloidyFilterRun
cd BlatPloidyFilterRun
echo "Generated folder for the run : "
pwd

rm -f *


# Setting output dir 

outputfolder=$( pwd )
outputfolder="${outputfolder}/BLAT_PLOIDY_FILTERED_OUTPUT"
mkdir ${outputfolder}

echo
echo "Run output will go to folder : ${outputfolder}"
echo



echo "Starting run with parameters :"
echo

echo "GENOME ${GENOME}" > parameters_norm.log
echo "oligofile ${oligofile}" >> parameters_norm.log
echo "recoordinatefile ${recoordinatefile}" >> parameters_norm.log
echo "dataprefixFLASHED ${dataprefixFLASHED}" >> parameters_norm.log
echo "dataprefixNONFLASHED ${dataprefixNONFLASHED}" >> parameters_norm.log

echo "reuseBLATpath ${reuseBLATpath} " >> parameters_norm.log
echo "CaptureFilterPath ${CaptureFilterPath}" >> parameters_norm.log
echo "GenomeFasta ${GenomeFasta}" >> parameters_norm.log
echo "ucscBuild ${ucscBuild}" >> parameters_norm.log
echo "datafolder ${datafolder}" >> parameters_norm.log
echo "outputfolder ${outputfolder}" >> parameters_norm.log
echo "extend ${extend}" >> parameters_norm.log
echo "ploidyfilter ${ploidyfilter} (1 yes, 0 no)" >> parameters_norm.log
echo "stepSize ${stepSize}" >> parameters_norm.log
echo "tileSize ${tileSize}" >> parameters_norm.log
echo "minScore ${minScore}" >> parameters_norm.log
echo "maxIntron ${maxIntron}" >> parameters_norm.log
echo "oneOff ${oneOff}" >> parameters_norm.log

cat parameters_norm.log


# Testing file existence..

testedFile=$( echo ${oligofile} )
fileTesting
testedFile=$( echo ${recoordinatefile} )
fileTesting
testedFile=$( echo ${GenomeFasta} )
fileTesting

# If we call this as intra-house stand-alone script
if [ "${pipelinecall}" -eq 0 ] ; then

module unload bedtools
module unload blat

module load bedtools/2.17.0
module load blat/35

module unload samtools
# The 1.x is needed - as we use the "overlap bed file" in samtools view, which is "new" feature.
module load samtools/1.1

module list

fi


cp ${CaptureFilterPath}/1_blat.sh .
chmod u=rwx ./1_blat.sh

printThis="-------------------------------------"
printToLogFile
printThis="Running blat filter generation for each oligo.."
printToLogFile

echo "${CaptureFilterPath}/1_blat.sh -o ${oligofile} -f ${GenomeFasta} -u ${ucscBuild} -r ${recoordinatefile} -p ${CaptureFilterPath} -e ${extend} --blatparams ${blatparams} --reusefile ${reuseBLATpath}"
echo "${CaptureFilterPath}/1_blat.sh -o ${oligofile} -f ${GenomeFasta} -u ${ucscBuild} -r ${recoordinatefile} -p ${CaptureFilterPath} -e ${extend} --blatparams ${blatparams} --reusefile ${reuseBLATpath}"  >> "/dev/stderr"

cp ${CaptureFilterPath}/1_blat.sh .
chmod u=rwx 1_blat.sh
./1_blat.sh -o ${oligofile} -f ${GenomeFasta} -u ${ucscBuild} -r ${recoordinatefile} -p ${CaptureFilterPath} -e ${extend} --blatparams ${blatparams} --reusefile ${reuseBLATpath}
rm -f 1_blat.sh

# Here (or to the above script) we need to add --globin functionality
# At the moment we do not generate the HbaCombined and HbbCombined gfc files

printThis="-------------------------------------"
printToLogFile
printThis="Filtering ccanalyser output files (reading files from ${datafolder} ).."
printToLogFile

# We need to find the corrsponding file names.
# 1) for gff file in datafolder
# 2) run ploidy filter (if ploidy filter file exists)
# 3) for ploidy-filtered gff
# 4) if exists blat-filter-file, blat-filter
# 5) else copy to be blat-filtered file

##########################################################
# First we check, if we want to do ploidyfilter..
##########################################################

ploidyWillBeRan=1
ploidyPath=""


if [ "${ploidyfilter}" -eq 0 ] ; then
    echo "No ploidy filtering requested - skipping ploidy filter !"
    ploidyWillBeRan=0
else
    
    weHavePloidyFile=0
    setPloidyPath
    
    # The above will set weHavePloidyFile=0 , if the genome wasn't listed in the genomes having blacklist file.
    
    if [ "${weHavePloidyFile}" -eq 1 ] ; then
    # Now we know, that weHavePloidyFile is only 1 , if we actually have a genome which has blacklist file.
    # Proceeding to filtering, then !
    ploidyWillBeRan=1
    
    else
    echo "Genome ${GENOME} does not have ploidy regions listing available - SKIPPING PLOIDY FILTERING ! "    
    ploidyWillBeRan=0
    
    fi

fi

##########################################################
# Now we run ploidy filter..
##########################################################

if [ "${ploidyWillBeRan}" -eq 1 ] ; then
    
printThis="-------------------------------------"
printToLogFile
printThis="Generating ploidy regions list for filtering.."
printToLogFile

# Avoid ending up in endless loop in *.gff

#input dir
mkdir TEMPdir
# output dir
mkdir TEMPdir2

# Here, testing if we are just running to get the blat stuff done (if seen no captures here, saying EXIT )

areWeActuallyHavingGffFiles=$(($( ls ${datafolder}/*.gff | grep -c "" )))

if [ "${areWeActuallyHavingGffFiles}" -eq 0 ]; then
    
    printThis="No reported fragments found - to apply BLAT-filtered regions to ! "
    printToLogFile
    printThis="( If this was BLAT-generation run, this is what you wanted ) "
    printToLogFile
    
    printThis="Your psl-files for BLAT-filtering can be found in folder :\n $( pwd )/BlatPloidyFilterRun/REUSE_blat/"
    printToLogFile

    printThis="EXITING !"
    printToLogFile
    
    exit 1
    
fi


cp ${datafolder}/*.gff $file TEMPdir/.
   
for file in TEMPdir/${dataprefixFLASHED}*.gff
do
    
    #intersectappend.pl <a gff3 file> <b gff3 file> <facet name> <return value true> <return value false>
    
    oligoname=$( echo $file | sed 's/.*'${dataprefixFLASHED}'_//' | sed 's/.gff$//' )
    newname=$( echo $file | sed 's/.*\///' | sed 's/.gff$//' )
    
    echo "${oligoname} FLASHED .."
    ploidyGFFoverlap
    
done

for file in TEMPdir/${dataprefixNONFLASHED}*.gff
do
    
    #intersectappend.pl <a gff3 file> <b gff3 file> <facet name> <return value true> <return value false>
    
    oligoname=$( echo $file | sed 's/.*'${dataprefixNONFLASHED}'_//' | sed 's/.gff$//' )
    newname=$( echo $file | sed 's/.*\///' | sed 's/.gff$//' )

    echo "${oligoname} NONFLASHED .."
    flashstatus="NONFLASHED"
    ploidyGFFoverlap    
    
done

else
# If we don't ploidy filter, we copy, with name _noPF.gff
    
for file in TEMPdir/${dataprefixFLASHED}*.gff
do
    oligoname=$( echo $file | sed 's/.*'${dataprefixFLASHED}'_//' | sed 's/.gff$//' )
    newname=$( echo $file | sed 's/.*\///' | sed 's/.gff$//' )
    cp ${file} TEMPdir2/${newname}_noPF.gff
    
done

for file in TEMPdir/${dataprefixNONFLASHED}*.gff
do
   
    oligoname=$( echo $file | sed 's/.*'${dataprefixNONFLASHED}'_//' | sed 's/.gff$//' )
    newname=$( echo $file | sed 's/.*\///' | sed 's/.gff$//' )
    cp ${file} TEMPdir2/${newname}_noPF.gff    

done
    
fi

# Deleting temporary files as last step..
rm -rf TEMPdir

##########################################################
# First we check if we can run blat filter - if we have something to filter
# Then we run it
##########################################################

printThis="-------------------------------------"
printToLogFile
printThis="Generating blat-excluded regions list for blat filtering.."
printToLogFile


for file in TEMPdir2/${dataprefixFLASHED}*PF.gff
do
    
    oligoname=$( echo $file | sed 's/.*'${dataprefixFLASHED}'_//' | sed 's/_noPF.gff$//' | sed 's/_PF.gff$//' )
    echo "${oligoname} FLASHED.."
    newname=$( echo $file | sed 's/.*\///' | sed 's/.gff$//' )
    
    blatGFFoverlap
   
done

for file in TEMPdir2/${dataprefixNONFLASHED}*PF.gff
do
  
    oligoname=$( echo $file | sed 's/.*'${dataprefixNONFLASHED}'_//' | sed 's/_noPF.gff$//' | sed 's/_PF.gff$//' )
    echo "${oligoname} NONFLASHED.."
    newname=$( echo $file | sed 's/.*\///' | sed 's/.gff$//' )
    
    blatGFFoverlap
    
done

rm -rf TEMPdir2

##########################################################
# We make files, where we save only filtered lines..
##########################################################

printThis="-------------------------------------"
printToLogFile
printThis="Preparing for SAM file filtering - saving only filtered lines.."
printToLogFile

for file in ${outputfolder}/*BF.gff
do

    newname=$( echo $file | sed 's/.*\///' | sed 's/_noPF_noBF.gff$//' | sed 's/_PF_noBF.gff$//' | sed 's/_noPF_BF.gff$//' | sed 's/_PF_BF.gff$//' )

    # We have to do grep -v here, as we don't know which of the filter combinations we actually have..
    cat $file | grep 'PloidyRegion=TRUE' > ${outputfolder}/${newname}_forPloidyFiltering.gff
    cat $file | grep 'BlatFilteredRegion=TRUE' > ${outputfolder}/${newname}_forBlatFiltering.gff
    cat ${outputfolder}/${newname}_forPloidyFiltering.gff ${outputfolder}/${newname}_forBlatFiltering.gff | sort -k1,1 -k4,4n | uniq > ${outputfolder}/${newname}_forBlatAndPloidyFiltering.gff
    
done

printThis="-------------------------------------"
printToLogFile
printThis="Filtering reporter SAM files for ploidy and blat regions, and combining filtered SAM files for re-run in CCanalyser.."
printToLogFile

#oligoname=$( echo $file | sed 's/.*'${dataprefix}'_//' | sed 's/.gff$//' )

printThis="-------------------------------------"
printToLogFile
printThis="Flashed sam filtering.."
printToLogFile

dataprefix="${dataprefixFLASHED}" 
rm -f TEMPheading_${dataprefix}.sam
rm -f TEMP_${dataprefix}_combined.sam   
filterSams

printThis="-------------------------------------"
printToLogFile
printThis="Nonflashed sam filtering.."
printToLogFile

dataprefix="${dataprefixNONFLASHED}" 
rm -f TEMPheading_${dataprefix}.sam
rm -f TEMP_${dataprefix}_combined.sam   
filterSams

    
# Make bed file of all blat-filter-marked DPNII regions..

cat ${outputfolder}/*.gff | grep BlatFilteredRegion=TRUE | cut -f 1,3,4,5 | awk '{ print $1"\t"$3"\t"$4"\t"$2 }' > ${outputfolder}/blatFilterMarkedREfragments.bed

printThis="Combined filtered SAM file - final touches.."
printToLogFile 

ls -lht TEMP*.sam
ls -lht TEMP*.sam >> "/dev/stderr"

dataprefix="${dataprefixFLASHED}"
cat TEMPheading_${dataprefix}.sam | sed 's/SO:coordinate/SO:unsorted/' | cat - TEMP_${dataprefix}_combined.sam > ${outputfolder}/${dataprefix}_filtered_combined.sam
rm -f TEMPheading_${dataprefix}.sam TEMP_${dataprefix}_combined.sam

dataprefix="${dataprefixNONFLASHED}"

cat TEMPheading_${dataprefix}.sam | sed 's/SO:coordinate/SO:unsorted/' | cat - TEMP_${dataprefix}_combined.sam > ${outputfolder}/${dataprefix}_filtered_combined.sam
rm -f TEMPheading_${dataprefix}.sam TEMP_${dataprefix}_combined.sam

ls -lht ${outputfolder}/*filtered_combined.sam
ls -lht ${outputfolder}/*filtered_combined.sam >> "/dev/stderr"


###########################################

logfolder=$( pwd )
echo "-------------------------------------"
echo "Run output log folder contents ( ${logfolder} }"
echo

ls -lht ${logfolder}

cd ..
thisfolder=$( pwd )
echo "-------------------------------------"
echo "Run starting folder contents ( ${thisfolder} }"
echo

ls -lht ${thisfolder}

echo "-------------------------------------"
echo "Run output folder contents ( ${outputfolder} }"
echo
ls -lht ${outputfolder}

echo "-------------------------------------"
echo "Generated filtered SAM files ( in ${outputfolder} }"
echo
ls -lht ${outputfolder} | grep "_filtered_combined.sam"


echo "-------------------------------------"
echo
echo "Run was started in folder : ${thisfolder}"
echo "Run output log was produced to folder : ${logfolder} "
echo "Run output was produced to folder : ${outputfolder}"
echo 

