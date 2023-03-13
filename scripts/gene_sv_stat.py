
import re
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("-v","--vcf",help="Vcf file")
parser.add_argument("-g","--gff",help="Gff file")
parser.add_argument("-o","--out",default="out",help="Output pre")

args=parser.parse_args()


def Read_vcf(filename):
	sv_set={}
	with open(filename) as lines:
		for line in lines:
			if line.startswith("#"):
				continue
			sv_id=line.split("\t")[2]
			chr_id=line.split("\t")[0]
			start=int(line.split("\t")[1])
			end=int(re.findall("END=(.*?);",line)[0])
			svtype=re.findall("SVTYPE=(.*?);",line)[0]
			sv_set[sv_id]=[chr_id,start,end,svtype]
	return sv_set

def Obtain_svtype(sv_set):
	svtype_set={}
	for sv_id in sv_set.keys():
		if sv_set[sv_id][3] in svtype_set.keys():		
			svtype_set[sv_set[sv_id][3]] +=1
		else:
			svtype_set[sv_set[sv_id][3]] =1
	return svtype_set

def Find_cds_overlap(filename,sv_set):
	cds_overlap_gene={}
	with open(filename) as lines:
		for line in lines:
			if line.startswith("#"):
				continue
			if line.split("\t")[2]=='CDS':
				chr_id=line.split("\t")[0]
				start=int(line.split("\t")[3])
				end=int(line.split("\t")[4])
				gene_id=re.findall(";Parent=(.*?)\n",line)[0]
				for sv_id in sv_set.keys():
					sv=sv_set[sv_id]
					if chr_id != sv[0]:
						continue
					if sv[1] > end or sv[2] < start:
						continue
					else:
						if gene_id in cds_overlap_gene.keys():
							cds_overlap_gene[gene_id][sv_id]=0
						else:
							cds_overlap_gene[gene_id]={sv_id:0}
	return cds_overlap_gene

def Fil_svtype_overlap_gene(gene_set,svtype):
	outset={}
	for gene_id in gene_set.keys():
		sv_ids=gene_set[gene_id]
		for sv_id in sv_ids.keys():
			if sv_id.startswith(svtype):
				if gene_id in outset.keys():
					outset[gene_id][sv_id]=0
				else:
					outset[gene_id]={sv_id:0}
	return outset				

def Find_gene_overlap(filename,sv_set,svtype):
		gene_overlap={}
		with open(filename) as lines:
			for line in lines:
				if line.startswith("#"):
					continue
				if line.split("\t")[2]=='gene':
					chr_id=line.split("\t")[0]
					start=int(line.split("\t")[3])
					end=int(line.split("\t")[4])
					gene_id=re.findall(";Name=(.*?)\n",line)[0]
					for sv_id in sv_set.keys():
						sv=sv_set[sv_id]
						if chr_id != sv[0]:
							continue
						if sv[1] <= start and sv[2] >= end and sv[3]==svtype:
							if gene_id in gene_overlap.keys():
								gene_overlap[gene_id][sv_id]=0
							else:
								 gene_overlap[gene_id]={sv_id:0}
		return gene_overlap

def Remove_whole_gene(cds_gene_set,gene_set):
	outset={}
	for cds_gene in cds_gene_set.keys():
		if cds_gene not in gene_set.keys():
			outset[cds_gene]=cds_gene_set[cds_gene]
		else:
			if cds_gene_set[cds_gene] == gene_set[cds_gene]:
				continue
			else:
				cds_sv_set=cds_gene_set[cds_gene]
				gene_sv_set=gene_set[cds_gene]
				for sv_id in cds_sv_set.keys():
					if sv_id not in gene_sv_set.keys():
						if cds_gene in outset.keys():
							outset[cds_gene][sv_id]=0
						else:
							outset[cds_gene]={sv_id:0}
	return outset

def Print_gene_set(gene_set,filename):
	with open(filename,'w') as out:
		for gene_id in gene_set.keys():
			sv_set=gene_set[gene_id]
			sv=""
			for sv_id in sv_set.keys():
				sv=sv+"\t"+sv_id
			out.write(gene_id+sv+"\n")
		
sv_set=Read_vcf(args.vcf)
svtype_set=Obtain_svtype(sv_set)
print("Finish Read SV")
cds_overlap_gene=Find_cds_overlap(args.gff,sv_set)

cds={}
for svtype in svtype_set.keys():
	if svtype == 'DUP':
		dup_whole=Find_gene_overlap(args.gff,sv_set,svtype)
		dup_cds=Fil_svtype_overlap_gene(cds_overlap_gene,svtype)
		dup_only_cds=Remove_whole_gene(dup_cds,dup_whole)
		cds[svtype]=dup_only_cds
	elif svtype == 'INV':
		inv_whole=Find_gene_overlap(args.gff,sv_set,svtype)
		inv_cds=Fil_svtype_overlap_gene(cds_overlap_gene,svtype)
		inv_only_cds=Remove_whole_gene(inv_cds,inv_whole)
		cds[svtype]=inv_only_cds
	else:
		cds[svtype]=Fil_svtype_overlap_gene(cds_overlap_gene,svtype)
cds_file_list=""
for svtype in cds.keys():
	filename=args.out+"_"+svtype+"_cds.txt"
	cds_file_list+=filename+" "
	Print_gene_set(cds[svtype],filename)
	

dup_whole_filename=args.out+"_DUP_whole.txt"
inv_whole_filename=args.out+"_INV_whole.txt"
Print_gene_set(dup_whole,dup_whole_filename)
Print_gene_set(inv_whole,inv_whole_filename)
dup_gene_filename=args.out+"_duplicated_gene.txt"
inv_gene_filename=args.out+"_inverted_gene.txt"
other_gene_filename=args.out+"_other_gene.txt"
os.system("cut -f 1 "+dup_whole_filename+"|sort -u >"+dup_gene_filename)
os.system("cut -f 1 "+inv_whole_filename+"|sort -u >"+inv_gene_filename)
os.system("cat "+cds_file_list+"|cut -f 1 |sort -u >"+other_gene_filename)	
print("Complete")
