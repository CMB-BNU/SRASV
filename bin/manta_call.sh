#!/bin/bash

#software
dir=`dirname $0`
if [ ${dir:0:1} != "/"  ]; then
	scriptpath=`pwd`"/"`dirname $0`
else
	scriptpath=`dirname $0`
fi
echo "Manta scripts in: $scriptpath"

while read line
do
	software=`echo $line|awk '{print $1}'`
	case $software in
	Manta_bin)
		manta_bin=`echo $line|awk '{print $2}'`
		;;
	SAMtools)
		samtools=`echo $line|awk '{print $2}'`
		;;
	Python2)
		python2=`echo $line|awk '{print $2}'`
		;;
	Perl)
		perl=`echo $line|awk '{print $2}'`
		;;
	esac
done<$scriptpath/configure
echo "configure file in: $scriptpath/../configure"

#parameters
Usage (){
	echo -e "\n\t\tUsage:  manta_call.sh [-h] [-t] [-r] [-b] [-s] [-o]\n"
	echo -e "\t\t\t-h: Print help message"
	echo -e "\t\t\t-t: Number of threads [Default 8]"
	echo -e "\t\t\t-r: Reference genome"
	echo -e "\t\t\t-b: Dir only contains your indexed bam files"
	echo -e "\t\t\t-o: Output dir [Default out]\n"
	exit 1
}

outpath=`pwd`"/out"
np=8

while getopts ht:r:b:o: varname
do
	case $varname in
	h)
		Usage
		exit
		;;
	t)
		np=$OPTARG
		;;
	r)
		ref_fasta=$OPTARG
		if [ ${ref_fasta:0:1} != "/"  ]; then
			ref_fasta=`pwd`"/"$ref_fasta
		fi
		if [ ! -f $ref_fasta ];then
			echo "The ref file $ref_fasta not exist"
			exit
		fi
		;;
	b)
		bampath=$OPTARG
		if [ ${bampath:0:1} != "/"  ]; then
			bampath=`pwd`"/"$bampath
		fi
		if [ ! -d $bampath ];then
			echo "The bam path $bampath not exist"
			exit	
		fi
		;;
	o)
		outpath=$OPTARG
		if [ ${outpath:0:1} != "/"  ]; then
			outpath=`pwd`"/"$outpath
		fi
		;;
	:)
		echo "the option -$OPTARG require an arguement"
		exit 1
		;;
	?)
		echo "Invaild option: -$OPTARG"
		exit 2
		;;
	esac
done

workpath=`pwd`"/manta_work"
if [ ! -d $workpath ]; then
	mkdir -p $workpath
fi

if [ ! -d $outpath ]; then
	mkdir -p $outpath
fi

ls $bampath | cut -f 1 -d "."|sort -u   > $workpath/bamfiles
list=$workpath/bamfiles
start_time=`date +%Y%m%d-%H:%M`

echo "Manta start_time: $start_time"
echo "--Number of threads: $np"
echo "--Work dir: $workpath"
echo "--Reference genome: $ref_fasta"
echo "--List of bam files: $workpath/bamfiles"

f_script=$scriptpath/manta_f.pl
configManta=$manta_bin"/configManta.py"
convertInversion=$manta_bin"/convertInversion.py"

p_w_d=`pwd`
cd $workpath

while read line
do
	echo "Start: $line"
	$python2 $configManta --bam $bampath/${line}.bam --referenceFasta $ref_fasta --runDir $workpath
	$python2 runWorkflow.py -j $np
	mv results/variants/diploidSV.vcf.gz ${line}.vcf.gz
	gunzip ${line}.vcf.gz
	rm runWorkflow.py
	rm -r workspace
	$python2 $convertInversion $samtools $ref_fasta ${line}.vcf  >${line}.nf.vcf
	$perl $f_script ${line}.nf.vcf $outpath/${line}.manta.vcf
	f_time=`date +%Y%m%d-%H:%M`
	echo "Finish: $line $f_time"
done< $list

cd $p_w_d
touch $outpath/finish_manta
echo "Finish"
