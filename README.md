# SRASV: Short-Read Alignment Structural Variants calling pipeline

## Dependencies
You can configure softwares in SRASV/bin/configure
### 1. SV calling
1. Perl
2. Python2 
3. Python3
4. BWA 
5. SAMtools
6. Picard
7. BAMtools 
8. BCFtools
9. Delly
10. Lumpy
11. Manta
12. Pindel
13. SVTyper
14. SURVIVOR

### 2. GWAS
1. Python3
2. R (packages: 1.optparse, 2.lfmm, 3.vcfR, 4.dplyr)

## Installation

```bash
git clone https://github.com/CMB-BNU/SRASV.git
```

## Running

### 1. SV calling
		Usage:  bin/sv_calling.sh [-h] [-t] [-r] [-l] [-q] [-o]

			-h: Print help message
			-t: Number of threads [Default 8]
			-r: Reference genome,indexed by BWA and SAMtools
			-l: Read length [Default 150]
			-q: Dir only contains your fastq files. File name format: id1_1.fq.gz id1_2.fq.gz id2_1.fq.gz id2_2.fq.gz ...
			-o: Output dir [Default out]

**Example:**
```bash
bin/sv_calling.sh -t 8 -r ref.fa -l 150 -q fastqdir/ -o out
```

You can also run Delly, Lumpy, Manta, and/or Pindel independently:
#### 1) Delly
		Usage:  bin/delly_call.sh [-h] [-t] [-r] [-b] [-s] [-o]

			-h: Print help message
			-t: Number of threads [Default 8]
			-r: Reference genome
			-b: Dir only contains your indexed bam files
			-o: Output dir [Default out]

**Example:**
```bash
bin/delly_call.sh -t 8 -r ref.fa -b bamdir/ -o out
```

#### 2) Lumpy
		Usage:  bin/lumpy_call.sh [-h] [-t] [-r] [-b] [-s] [-o]

			-h: Print help message
			-t: Number of threads [Default 8]
			-r: Read_length
			-b: Dir only contains your indexed bam files
			-o: Output dir [Default out]

**Example:**
```bash
bin/lumpy_call.sh -t 8 -r 150 -b bamdir/ -o out
```

#### 3) Manta
		Usage:  bin/manta_call.sh [-h] [-t] [-r] [-b] [-s] [-o]

			-h: Print help message
			-t: Number of threads [Default 8]
			-r: Reference genome
			-b: Dir only contains your indexed bam files
			-o: Output dir [Default out]

**Example:**
```bash
bin/manta_call.sh -t 8 -r ref.fa -b bamdir/ -o out
```

#### 4) Pindel
		Usage:  bin/pindel_call.sh [-h] [-t] [-r] [-b] [-s] [-o]

			-h: Print help message
			-t: Number of threads [Default 8]
			-r: Reference genome
			-b: Dir only contains your indexed bam files
			-o: Output dir [Default out]

**Example:**
```bash
bin/pindel_call.sh -t 8 -r ref.fa -b bamdir/ -o out
```

### 2. GWAS
		Usage:  bin/gwas.sh [-h] [-v] [-c] [-k] [-m] [-f] [-o]

			-h: Print help message
			-v: VCF file
			-c: CSV file
			-k: Number of latent factors [default 2]
			-m: Minor allele frequency threshold [default 0.01]
			-f: FDR threshold [default 0.05]
			-o: Output dir [Default out]

**Example:**

```bash
bin/gwas.sh -v test.vcf -o test.csv -k 2 -m 0.01 -f 0.05 -o out
```

Example of CSV file: 

	sample,parameter1,parameter2
	id1,30,0.4
	id2,50,0.5
	id3,90,0.2

### 3. Other scripts (in SRASV/scripts)

#### 1. frequency_sv_stat.py
Script for dividing SVs into singleton (only have one allele), polymorphic (more than one allele and allele frequency < 0.5), major (0.5 ≤ allele frequency < 1), and shared (allele frequency = 1).

		Usage: python frequency_sv_stat.py [-h] [-v VCF] [-o OUT]
		
		Optional arguments:
		  -h, --help         show this help message and exit
		  -v VCF, --vcf VCF  Vcf file
		  -o OUT, --out OUT  Output pre

**Example:**

```bash
python frequency_sv_stat.py -v merge.vcf -o out
```

#### 2. gene_sv_stat.py 
Script for obtaining genes whose CDS regions overlapped with SVs, those genes will be classified into three classes: 1) duplicated genes (genes within DUPs), 2) inverted genes (genes within INVs), and 3) others (genes that were damaged by SVs).

		Usage: python gene_sv_stat.py [-h] [-v VCF] [-g GFF] [-o OUT]
		
		Optional arguments:
		  -h, --help         show this help message and exit
		  -v VCF, --vcf VCF  Vcf file
		  -g GFF, --gff GFF  Gff file
		  -o OUT, --out OUT  Output pre
**Example:**

```bash
python gene_sv_stat.py -v merge.vcf -g gene.gff -o out
```

Example of gff file:

	chr1    EVM     gene    504225  504878  .       -       .       ID=JMA033926;Name=JMA033926.1
	chr1    EVM     mRNA    504225  504878  .       -       .       ID=JMA033926.1;Parent=JMA033926;Name=JMA033926.1
	chr1    EVM     exon    504225  504878  .       -       .       ID=JMA033926.1.exon1;Parent=JMA033926.1
	chr1    EVM     CDS     504225  504878  .       -       0       ID=cds.JMA033926.1;Parent=JMA033926.1
	chr1    EVM     gene    523885  524255  .       +       .       ID=JMA033951;Name=JMA033951.1
	chr1    EVM     mRNA    523885  524255  .       +       .       ID=JMA033951.1;Parent=JMA033951;Name=JMA033951.1
	chr1    EVM     exon    523885  524007  .       +       .       ID=JMA033951.1.exon1;Parent=JMA033951.1
	chr1    EVM     CDS     523885  524007  .       +       0       ID=cds.JMA033951.1;Parent=JMA033951.1
	chr1    EVM     exon    524121  524255  .       +       .       ID=JMA033951.1.exon2;Parent=JMA033951.1
	chr1    EVM     CDS     524121  524255  .       +       0       ID=cds.JMA033951.1;Parent=JMA033951.1

## Citation
Please cite:
