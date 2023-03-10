import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("-v","--inputvcf",help="Input vcf file")
parser.add_argument("-g","--gwas",help="GWAS result file")
parser.add_argument("-f","--fdr",type=float,default=0.05,help="FDR threshold")
parser.add_argument("-o","--outputvcf",default="out.vcf",help="Output vcf file")

args=parser.parse_args()

sv_set={}
with open(args.inputvcf) as lines:
	vcf_head=""
	for line in lines:
		if line.startswith("#"):
			vcf_head+=line
			continue
		sv_id=line.split("\t")[0]+"_"+line.split("\t")[1]
		sv_set[sv_id]=line

with open(args.outputvcf,'w') as outfile:
	outfile.write(vcf_head)
	with open(args.gwas) as lines:
		for line in lines:
			if line.startswith("ch"):
				continue
			if float(line.split(" ")[3]) < args.fdr:
				for key in sv_set.keys():
					if line.split(" ")[1] == key:
						outfile.write(sv_set[key])
