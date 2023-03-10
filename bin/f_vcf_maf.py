import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-v","--vcf",help="Vcf file")
parser.add_argument("-m","--maf",type=float,default=0.01,help="Minor allele frequency threshold")
parser.add_argument("-o","--out",default="out.vcf",help="Output file")

args=parser.parse_args()

def Cal_maf(lists):
	total=0
	nums=0
	for num in lists:
		total+=2
		nums+=num
	af=nums/total
	if af > 0.5:
		maf=1-af
	else:
		maf=af
	return maf

with open(args.out,'w') as outfile:
	with open(args.vcf) as lines:
		for line in lines:
			if line.startswith("#"):
				outfile.write(line)
				continue
			gts=[]
			parts=line.split("\t")
			for part in parts[9:]:
				gt=part.split(":")[0]
				if gt == './.' or gt == '0/0':
					gts.append(0)
				elif gt == '0/1':
					gts.append(1)
				elif gt == '1/1':
					gts.append(2)
			maf=Cal_maf(gts)
			if maf > args.maf:
				outfile.write(line)

