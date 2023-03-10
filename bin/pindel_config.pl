#!/usr/bin/perl
open(IN,"$ARGV[0]")or die "can't open $ARGV[0],$!";
$or=$/;
$/=">";
while(<IN>){
	/sampleid:(.*?):/;
	$id=$1;
	next if ($id eq " " or $id eq "");
	/Median insert size \(absolute value\): (.*?)\n/;
	$insert=$1;
	open(OUT,">$ARGV[1]/$id")or die "can't write $id,$!";
	print OUT "$ARGV[2]/$id.bam\t$insert\t$id";	#目录改成你的bam文件所在的目录
	close OUT;
}

$/=$or;
close IN;
