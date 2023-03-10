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

## Citation
Please cite:
