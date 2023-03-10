#!/bin/bash

#software
dir=`dirname $0`
if [ ${dir:0:1} != "/"  ]; then
	scriptpath=`pwd`"/"`dirname $0`
else
	scriptpath=`dirname $0`
fi
echo "Pindel scripts in: $scriptpath"

while read line
do
	software=`echo $line|awk '{print $1}'`
	case $software in
	Pindel_bin)
		pindel_bin=`echo $line|awk '{print $2}'`
		;;
	BAMtools)
		bamtools=`echo $line|awk '{print $2}'`
		;;
	Perl)
		perl=`echo $line|awk '{print $2}'`
		;;
	esac
done<$scriptpath/../configure
echo "configure file in: $scriptpath/../configure"

#parameters
Usage (){
	echo -e "\n\t\tUsage:  pindel_call.sh [-h] [-t] [-r] [-b] [-s] [-o]\n"
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

workpath=`pwd`"/pindel_work"
if [ ! -d $workpath ]; then
	mkdir -p $workpath
fi

if [ ! -d $outpath ]; then
	mkdir -p $outpath
fi

ls $bampath | cut -f 1 -d "." |sort -u  > $workpath/bamfiles
list=$workpath/bamfiles
start_time=`date +%Y%m%d-%H:%M`

echo "Pindel start_time: $start_time"
echo "--Number of threads: $np"
echo "--Work dir: $workpath"
echo "--Reference genome: $ref_fasta"
echo "--List of bam files: $workpath/bamfiles"

configpl=$scriptpath/pindel_config.pl
f_script=$scriptpath/pindel_f.pl
pindel=$pindel_bin/pindel
pindel2vcf=$pindel_bin/pindel2vcf

while read line
do
	echo -e ">\nsampleid:${line}:\n" >>$workpath/bam_stat.txt
	$bamtools stats -in $bampath/${line}.bam -insert >>$workpath/bam_stat.txt
done<$list

mkdir $workpath/config
$perl $configpl $workpath/bam_stat.txt $workpath/config $bampath

p_w_d=`pwd`
cd $workpath
while read line
do
	echo "Start: $line"
	$pindel -f $ref_fasta -i $workpath/config/${line} -o ${line} -g -M 4 -T $np 
	$pindel2vcf -P ${line} -r $ref_fasta -R J -d 20221023 -e 4 --min_size 50 -v ${line}.vcf 
	rm ${line}_*
	$perl $f_script ${line}.vcf $outpath/${line}.pindel.vcf
	f_time=`date +%Y%m%d-%H:%M`
	echo "Finish $line $f_time"
done<$list

end_time=`date +%Y%m%d-%H:%M`
cd $p_w_d
touch $outpath/finish_pindel
echo "Finish: $end_time"
