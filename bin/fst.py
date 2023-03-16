
import argparse
import os
import numpy as np
import re

parser = argparse.ArgumentParser()
parser.add_argument("-v","--vcf",help="Vcf file")
parser.add_argument("-p","--populations",help="File contains path to all population file")
parser.add_argument("-t","--threshold",type=float,default=0.05,help="Top ? FST")
parser.add_argument("-o","--out",default=".",help="Output dir")

args=parser.parse_args()

scriptpath=os.path.split(os.path.abspath(__file__))[0]
config_file=scriptpath+"/configure"
if not (os.path.isfile(config_file)):
	print(config_file,"does not exist",sep=" ")
	exit()

if not os.path.exists(args.out):
	os.mkdir(args.out)

with open(config_file) as lines:
	for line in lines:
		software=line.split(" ")[0]
		if software == "VCFtools":
			vcftools=line.replace("\n","").split("\t")[0].split(" ")[1]

pop=""
with open(args.populations) as lines:
	for line in lines:
		pop+=" --weir-fst-pop "
		pop+=line.replace("\n","")

outpre=args.out+"/"+args.vcf.replace(".vcf","")
os.system(vcftools+" --vcf "+args.vcf+" --out "+outpre+pop)

fst_file=outpre+".weir.fst"

fst_set=[]
with open (fst_file) as lines:
	for line in lines:
		if line.startswith("CHROM"):
			continue
		if line.split("\t")[2]=="-nan\n":
			continue
		fst=float(line.replace("\n","").split("\t")[2])
		fst_set.append(fst)

th_num=np.percentile(fst_set,100-(args.threshold*100))

def Read_vcf(filename):
	sv_set={}
	with open(filename) as lines:
		for line in lines:
			if line.startswith("#"):
				continue
			chr_id=line.split("\t")[0]
			start=int(line.split("\t")[1])
			sv_id=line.split("\t")[2]
			sv_type=re.findall("SVTYPE=(.*?);",line)[0]
			end=int(re.findall("END=(.*?);",line)[0])
			sv_set[sv_id]=[chr_id,sv_type,start,end]
	return sv_set

def Read_fst(filename):
	fst_set={}
	with open(filename) as lines:
		for line in lines:
			if line.startswith("CHROM"):
				continue
			chr_id=line.split("\t")[0]
			start=int(line.split("\t")[1])
			fst=float(line.split("\t")[2])
			fst_id=chr_id+"_"+str(start)
			fst_set[fst_id]=fst
	return fst_set

def Svtype_fst_stat(sv_set,fst_set,out_file,th):
	with open(outfile,'w') as out:
		for sv_id in sv_set.keys():
			fst_id=sv_set[sv_id][0]+"_"+str(sv_set[sv_id][2])
			fst=fst_set[fst_id]
			if fst >= th:
				out.write(sv_id+"\t"+str(fst)+"\n")

sv_set=Read_vcf(args.vcf)
fst_set=Read_fst(fst_file)
outfile=outpre+"_top_"+str(args.threshold)+"_fst_sv.txt"
Svtype_fst_stat(sv_set,fst_set,outfile,th_num)
