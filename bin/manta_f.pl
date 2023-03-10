#!/usr/bin/perl
open(IN,"$ARGV[0]")or die "can't open,$!";
open(OUT,">$ARGV[1]")or die "can't write,$!";
while(<IN>){
	if(/^#/){print OUT;next;}
	next if /\t0\/0:/;
	next if /IMPRECISE/;
	next unless /\tPASS\t/;
	next unless /:PASS:/;
	print OUT;
}
close IN;
close OUT;
