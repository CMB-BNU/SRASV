#!/bin/bash

#software
dir=`dirname $0`
if [ ${dir:0:1} != "/"  ]; then
	scriptpath=`pwd`"/"`dirname $0`
else
	scriptpath=`dirname $0`
fi
echo "Lumpy scripts in: $scriptpath"

while read line
do
	software=`echo $line|awk '{print $1}'`
	case $software in
	Lumpy_dir)
		lumpy_dir=`echo $line|awk '{print $2}'`
		;;
	SAMtools)
		samtools=`echo $line|awk '{print $2}'`
		;;
	SVTyper)
		svtyper=`echo $line|awk '{print $2}'`
		;;
	Perl)
		perl=`echo $line|awk '{print $2}'`
		;;
	esac
done<$scriptpath/configure
echo "configure file in: $scriptpath/../configure"

#parameters
Usage (){
	echo -e "\n\t\tUsage:  lumpy_call.sh [-h] [-t] [-r] [-b] [-s] [-o]\n"
	echo -e "\t\t\t-h: Print help message"
	echo -e "\t\t\t-t: Number of threads [Default 8]"
	echo -e "\t\t\t-r: Read_length"
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
		read_length=$OPTARG
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

workpath=`pwd`"/lumpy_work"
if [ ! -d $workpath ]; then
	mkdir -p $workpath
fi

if [ ! -d $outpath ]; then
	mkdir -p $outpath
fi

ls $bampath | cut -f 1 -d "."|sort -u   > $workpath/bamfiles
list=$workpath/bamfiles
start_time=`date +%Y%m%d-%H:%M`

echo "Lumpy start_time: $start_time"
echo "--Number of threads: $np"
echo "--Work dir: $workpath"
echo "--Read_length: $read_length"
echo "--List of bam files: $workpath/bamfiles"

f_script=$scriptpath/lumpy_f.pl
lumpy=$lumpy_dir"/bin/lumpy"
lumpy_script=$lumpy_dir"/scripts"
lumpypl=$scriptpath/lumpy.pl

echo "Start prepare"

while read line
do
	$samtools view -@ $np -b -F 1294 $bampath/${line}.bam > $workpath/${line}.discordants.unsorted.bam
	$samtools view -h -@ $np $bampath/${line}.bam | $lumpy_script/extractSplitReads_BwaMem -i stdin |$samtools view -Sb  -@ $np > $workpath/${line}.splitters.unsorted.bam
	$samtools sort -@ $np -o $workpath/${line}.splitters.bam $workpath/${line}.splitters.unsorted.bam
	$samtools sort -@ $np -o $workpath/${line}.discordants.bam $workpath/${line}.discordants.unsorted.bam
	rm $workpath/${line}.splitters.unsorted.bam
	rm $workpath/${line}.discordants.unsorted.bam
	echo "sampleid:$line" >>$workpath/mean.stdev.txt
	$samtools view $bampath/${line}.bam|tail -n+100000|$lumpy_script/pairend_distro.py  -r $read_length  -X 4 -N 10000 -o $workpath/${line}.lib1.histo 1>>$workpath/mean.stdev.txt 2>>$workpath/mean.stdev.txt		
done<$list

call_time=`date +%Y%m%d-%H:%M`
echo "Start SV calling: $call_time"

p_w_d=`pwd`
cp $lumpypl $workpath/
cd $workpath
$perl $lumpypl $lumpy $read_length
cd $p_w_d

gt_time=`date +%Y%m%d-%H:%M`
echo "Start genotype: $gt_time"

while read line
do
	echo "Start $line"
	$svtyper -i $workpath/${line}.vcf -o $workpath/${line}.gt.vcf -B $bampath/${line}.bam  
	rm $workpath/${line}.vcf
	$perl $f_script $workpath/${line}.gt.vcf $outpath/${line}.lumpy.vcf
	gt_time=`date +%Y%m%d-%H:%M`
	echo "Finish $line $gt_time"
done<$list

touch $outpath/finish_lumpy
end_time=`date +%Y%m%d-%H:%M`
echo "Finish: $end_time"
