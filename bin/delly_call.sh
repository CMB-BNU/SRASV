#!/bin/bash

#software
dir=`dirname $0`
if [ ${dir:0:1} != "/"  ]; then
	scriptpath=`pwd`"/"`dirname $0`
else
	scriptpath=`dirname $0`
fi
echo "Delly scripts in: $scriptpath"

while read line
do
	software=`echo $line|awk '{print $1}'`
	case $software in
	Delly)
		delly=`echo $line|awk '{print $2}'`
		;;
	BCFtools)
		bcftools=`echo $line|awk '{print $2}'`
		;;
	Perl)
		perl=`echo $line|awk '{print $2}'`
		;;
	esac
done<$scriptpath/configure
echo "configure file in: $scriptpath/configure"

#parameters
Usage (){
	echo -e "\n\t\tUsage:  delly_call.sh [-h] [-t] [-r] [-b] [-s] [-o]\n"
	echo -e "\t\t\t-h: Print help message"
	echo -e "\t\t\t-t: Number of threads [Default 8]"
	echo -e "\t\t\t-r: Reference genome"
	echo -e "\t\t\t-b: Dir only contains your indexed bam files"
	echo -e "\t\t\t-o: Output dir [Default out]\n"
	exit 1
}

np=8
outpath=`pwd`"/out"

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

workpath=`pwd`"/delly_work"
if [ ! -d $workpath ]; then
	mkdir -p $workpath
fi

if [ ! -d $outpath ]; then
	mkdir -p $outpath
fi

ls $bampath | cut -f 1 -d "."|sort -u  > $workpath/bamfiles
list=$workpath/bamfiles
start_time=`date +%Y%m%d-%H:%M`

echo "Delly start_time: $start_time"
echo "--Number of threads: $np"
echo "--Work dir: $workpath"
echo "--Reference genome: $ref_fasta"
echo "--List of bam files: $workpath/bamfiles"

f_script=$scriptpath/delly_f.pl

while read line
do
	start_time=`date +%Y%m%d-%H:%M`
	echo "Start ${line}: $start_time"
	$delly call -g $ref_fasta -o $workpath/${line}.delly.bcf $bampath/${line}.bam
	$bcftools view --threads $np $workpath/${line}.delly.bcf > $workpath/${line}.delly.nf.vcf
	rm $workpath/${line}.delly.bcf*
	$perl $f_script $workpath/${line}.delly.nf.vcf $outpath/${line}.delly.vcf
	end_time=`date +%Y%m%d-%H:%M`
	echo "Finish ${line}: $end_time"
done<$list
touch $outpath/finish_delly
