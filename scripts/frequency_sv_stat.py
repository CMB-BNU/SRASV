
import argparse
import re


parser = argparse.ArgumentParser()
parser.add_argument("-v","--vcf",help="Vcf file")
parser.add_argument("-o","--out",default="out",help="Output pre")

args=parser.parse_args()


def Cal_af(lists):
	total=0
	nums=0
	for num in lists:
		total+=2
		nums+=num
	af=nums/total
	return af

def Read_vcf_head(filename):
	head=""
	with open(filename) as lines:
		for line in lines:
			if line.startswith("#"):
				head=head + line
	return head

def F_vcf(filename,af_t):
	f_vcf=[]
	with open(filename) as lines:
		for line in lines:
			if line.startswith("#"):
				continue
			gts=[]
			parts=line.split("\t")
			for part in parts[9:]:
				gt=part.split(":")[0]
				if gt == './.':
					gts.append(0)
				elif gt == '0/1':
					gts.append(1)
				elif gt == '1/1':
					gts.append(2)
			af=Cal_af(gts)
			if af_t == "single":
				if af < 0.01:
					f_vcf.append(line)
			if af_t == "poly":
				if 0.01 < af < 0.5:
					f_vcf.append(line)
			if af_t == "major":
				if 0.5 <= af < 1:
					f_vcf.append(line)
			if af_t == "shared":
				if af == 1:
					f_vcf.append(line)
	return f_vcf

def Print_vcf(head,vcf,filename):
	with open(filename,'w') as out:
		out.write(head)
		for sv in vcf:
			out.write(sv)

head=Read_vcf_head(args.vcf)
single=F_vcf(args.vcf,"single")
poly=F_vcf(args.vcf,"poly")
major=F_vcf(args.vcf,"major")
shared=F_vcf(args.vcf,"shared")

sin_file=args.out+"_singleton.vcf"
poly_file=args.out+"_polymorphic.vcf"
major_file=args.out+"_major.vcf"
shared_file=args.out+"_shared.vcf"

Print_vcf(head,single,sin_file)
Print_vcf(head,poly,poly_file)
Print_vcf(head,major,major_file)
Print_vcf(head,shared,shared_file)
