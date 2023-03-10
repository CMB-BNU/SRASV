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
	BWA)
		bwa=`echo $line|awk '{print $2}'`
		;;
	SAMtools)
		samtools=`echo $line|awk '{print $2}'`
		;;
	Picard)
		picard=`echo $line|awk '{print $2}'`
		;;
	SURVIVOR)
		survivor=`echo $line|awk '{print $2}'`
		;;
	esac
done<$scriptpath/configure
echo "configure file in: $scriptpath/configure"

#parameters
Usage (){
	echo -e "\n\t\tUsage:  sv_calling.sh [-h] [-t] [-r] [-l] [-q] [-o]\n"
	echo -e "\t\t\t-h: Print help message"
	echo -e "\t\t\t-t: Number of threads [Default 8]"
	echo -e "\t\t\t-r: Reference genome,indexed by BWA and SAMtools"
	echo -e "\t\t\t-l: Read length [Default 150]"
	echo -e "\t\t\t-q: Dir only contains your fastq files. File name format: id1_1.fq.gz id1_2.fq.gz id2_1.fq.gz id2_2.fq.gz ..."
	echo -e "\t\t\t-o: Output dir [Default out]\n"
	exit 1
}

np=8
outpath=`pwd`"/out"
read_length=150

while getopts ht:r:l:q:o: varname
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
	l)
		read_length=$OPTARG
		;;
	q)
		fqpath=$OPTARG
		if [ ${fqpath:0:1} != "/"  ]; then
			fqpath=`pwd`"/"$fqpath
		fi
		if [ ! -d $fqpath ];then
			echo "The fastq path $fqpath not exist"
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

workpath=`pwd`"/sv_calling_work"
if [ ! -d $workpath/log ]; then
	mkdir -p $workpath/log
fi

if [ ! -d $outpath ]; then
	mkdir -p $outpath
fi

ls $fqpath | cut -f 1 -d "_"|sort -u  > $workpath/samples
list=$workpath/samples
start_time=`date +%Y%m%d-%H:%M`

echo "SV calling start_time: $start_time"
echo "--Number of threads: $np"
echo "--Work dir: $workpath"
echo "--Reference genome: $ref_fasta"
echo "--List of samples: $workpath/samples"


#mapping
while read sample
do
	$bwa mem -M -t $np $ref_fasta $fqpath/${sample}_1.fq.gz $fqpath/${sample}_2.fq.gz 1>$workpath/${sample}.f.sam 2>$workpath/log/${sample}.samlog
	$samtools view -@ $np -bS $workpath/${sample}.f.sam 1>$workpath/${sample}.f.bam 2>$workpath/log/${sample}.f.bamlog
	rm -f $workpath/${sample}.f.sam
	$samtools sort -@ $np -o $workpath/${sample}.bam $workpath/${sample}.f.bam
	rm -f $workpath/${sample}.f.bam
	$samtools index -@ $np $workpath/${sample}.bam
	map_time=`date +%Y%m%d-%H:%M`
	echo "Finish $sample : $map_time"
done<$list

bampath=$workpath/bam

if [ ! -d $bampath ]; then
	mkdir -p $bampath
fi

map_time=`date +%Y%m%d-%H:%M`
echo "Finish mapping : $map_time"
echo "Start to remove PCR duplication"

#mark dup and remove
while read sample
do
	if [ ! -f $bampath/${sample}.bam ]; then
		$picard MarkDuplicates -I $workpath/${sample}.bam -O $bampath/${sample}.bam --REMOVE_DUPLICATES true --MAX_RECORDS_IN_RAM 1000000 --MAX_FILE_HANDLES_FOR_READ_ENDS_MAP 1000 -M $workpath/${sample}.merits 2>$workpath/log/${sample}.picardlog
		$samtools index -@ $np $bampath/${sample}.bam
		rm $workpath/${sample}.bam
		re_time=`date +%Y%m%d-%H:%M`
		echo "Finish $sample : $re_time"
	fi
done<$list

end_time=`date +%Y%m%d-%H:%M`
echo "Finish removing PCR duplication : $end_time"

#SV calling
echo "Start SV calling"
np_calling=`expr $np / 4`
delly_out=$workpath"/delly_out"
lumpy_out=$workpath"/lumpy_out"
manta_out=$workpath"/manta_out"
pindel_out=$workpath"/pindel_out"

nohup bash $scriptpath/delly_call.sh -t $np_calling -r $ref_fasta -b $bampath -o $delly_out >$workpath/log/delly.log &
nohup bash $scriptpath/lumpy_call.sh -t $np_calling -r $read_length -b $bampath -o $lumpy_out >$workpath/log/lumpy.log &
nohup bash $scriptpath/manta_call.sh -t $np_calling -r $ref_fasta -b $bampath -o $manta_out >$workpath/log/manta.log &
nohup bash $scriptpath/pindel_call.sh -t $np_calling -r $ref_fasta -b $bampath -o $pindel_out >$workpath/log/pindel.log &

#Merge of SV set
while [ 1 ] ; do
	sleep 10m
	if [ -f $delly_out/finish_delly -a -f $lumpy_out/finish_lumpy -a -f $manta_out/finish_manta -a -f $pindel_out/finish_pindel ];then		
		end_time=`date +%Y%m%d-%H:%M`
		echo "Finish SV calling : $end_time"
		echo "Start merging"
		while read line
		do
			ls $delly_out/${line}.delly.vcf >>$workpath/tmp
			ls $lumpy_out/${line}.lumpy.vcf >>$workpath/tmp
			ls $manta_out/${line}.manta.vcf >>$workpath/tmp
			ls $pindel_out/${line}.pindel.vcf >>$workpath/tmp
			$survivor merge tmp 1000 4 1 1 0 50 $outpath/${line}.vcf
			ls $outpath/${line}.vcf >>$outpath/vcf.txt
			rm $workpath/tmp
		done <$list
		$survivor merge $outpath/vcf.txt 1000 1 1 1 0 50 $outpath/merge.vcf
		rm $outpath/vcf.txt
		rm -r delly_work
		rm -r lumpy_work
		rm -r manta_work
		rm -r pindel_work
		break
	fi
done

end_time=`date +%Y%m%d-%H:%M`
echo "Finish Merging : $end_time"
echo "Merged SV file: $outpath/merge.vcf"
echo "Complete"
