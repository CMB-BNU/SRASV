#!/bin/bash

#software
dir=`dirname $0`
if [ ${dir:0:1} != "/"  ]; then
	scriptpath=`pwd`"/"`dirname $0`
else
	scriptpath=`dirname $0`
fi
echo "Scripts in: $scriptpath"

while read line
do
	software=`echo $line|awk '{print $1}'`
	case $software in
	Python3)
		python3=`echo $line|awk '{print $2}'`
		;;
	Rscript)
		Rscript=`echo $line|awk '{print $2}'`
		;;	
	esac
done<$scriptpath/configure
echo "configure file in: $scriptpath/../configure"

#parameters
Usage (){
	echo -e "\n\t\tUsage:  gwas.sh [-h] [-v] [-c] [-k] [-m] [-f] [-o]\n"
	echo -e "\t\t\t-h: Print help message"
	echo -e "\t\t\t-v: VCF file"
	echo -e "\t\t\t-c: CSV file"
	echo -e "\t\t\t-k: Number of latent factors [default 2]"
	echo -e "\t\t\t-m: Minor allele frequency threshold [default 0.01]"
	echo -e "\t\t\t-f: FDR threshold [default 0.05]"
	echo -e "\t\t\t-o: Output dir [Default out]\n"
	exit 1
}

k=2
m=0.01
f=0.05
outpath=`pwd`"/out"

while getopts hv:c:k:m:f:o: varname
do
	case $varname in
	h)
		Usage
		exit
		;;
	v)
		vcf_file=$OPTARG
		if [ ${vcf_file:0:1} != "/"  ]; then
			vcf_file=`pwd`"/"$vcf_file
		fi
		if [ ! -f $vcf_file ];then
			echo "The vcf file $vcf_file not exist"
			exit
		fi
		;;
	c)	
		csv_file=$OPTARG
		if [ ${csv_file:0:1} != "/"  ]; then
			csv_file=`pwd`"/"$csv_file
		fi
		if [ ! -f $csv_file ];then
			echo "The csv file $csv_file not exist"
			exit
		fi
		;;
	k)
		k=$OPTARG
		;;
	m)
		m=$OPTARG
		;;
	f)
		f=$OPTARG
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

workpath=`pwd`"/gwas_work"
if [ ! -d $workpath/log ]; then
	mkdir -p $workpath/log
fi

if [ ! -d $outpath ]; then
	mkdir -p $outpath
fi

start_time=`date +%Y%m%d-%H:%M`
echo "GWAS start_time: $start_time"
echo "--Work dir: $workpath"
echo "--vcf file: $vcf_file"

$python3 $scriptpath/f_vcf_maf.py -v $vcf_file -m $m -o $workpath/f.vcf
echo "Filtered vcf file with MAF > $m: $workpath/f.vcf "
echo "Start GWAS"
$Rscript $scriptpath/gwas.R -v $workpath/f.vcf -c $csv_file -k $k -o $outpath > $workpath/log/gwas.log 2>&1
ls $outpath/*_pvalue.txt >$workpath/gwas_result_filelist

echo "GWAS result in:"
cat $workpath/gwas_result_filelist
echo "Start obtain vcf file with FDR > $f"
while read line
do
	$python3 $scriptpath/gwas_stat.py -v $workpath/f.vcf -g $line -f $f -o ${line}_fdr_${f}.vcf
done<$workpath/gwas_result_filelist

end_time=`date +%Y%m%d-%H:%M`
echo "Finish: $end_time"
