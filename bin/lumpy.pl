#!/usr/bin/perl
$lumpy=$ARGV[0];
$read_length=$ARGV[1];
open(IN,"mean.stdev.txt")or die "can't open mean.stdev.txt,$!";
while(<IN>){
	if(/sampleid:(.*?)\n/){		#适度修改
		$sample=$1;
	}
	if(/mean:(.*?)\tstdev:(.*?)\n/){
		$mean=$1;
		$stdev=$2;
		`$lumpy -mw 4 -tt 0 -pe id:$sample,bam_file:${sample}.discordants.bam,histo_file:${sample}.lib1.histo,mean:$mean,stdev:$stdev,read_length:$read_length,min_non_overlap:101,discordant_z:5,back_distance:10,weight:1,min_mapping_threshold:20 -sr id:${sample},bam_file:${sample}.splitters.bam,back_distance:10,weight:1,min_mapping_threshold:20 > ${sample}.vcf`
	}
}
close IN;
