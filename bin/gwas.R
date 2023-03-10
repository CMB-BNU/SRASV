#Library packages
library('optparse')
library("lfmm")
library("vcfR")
library("dplyr")

#Gain parameters
option_list <- list(
	make_option(c("-v", "--vcf"), type = "character", default = NULL,
		action = "store", help = "Vcf file"
	),
	make_option(c("-c", "--csv"), type = "character", default = NULL,
		action = "store", help = "Csv file"
	),
	make_option(c("-o", "--outdir"), type = "character", default = '.',
		action = "store", help = "Output dir [default out]"
	),
	make_option(c("-k", "--latent"), type = "numeric", default = 2,
		action = "store", help = "Number of latent factors [default 2]"
	)
)
opt = parse_args(OptionParser(option_list = option_list))

#
cucvcf <- read.vcfR(opt$vcf)
gtdf <- cucvcf@gt
gtindvs <- colnames(gtdf)
v_num <- nrow(gtdf)

phedf <- read.csv(opt$csv)
phe <- colnames(phedf)
phedf <- phedf[complete.cases(phedf), ]
pheindvs <- phedf$sample
filindvs <- intersect(gtindvs, pheindvs)
rownames(phedf) <- pheindvs
p_num <- ncol(phedf)-1
finalphedf <- scale(phedf[filindvs, -c(1)])

finalgtdf <- gtdf[, filindvs]
finalmadf <- substr(finalgtdf, 0, 3)
finalmadf2 <- case_when(finalmadf %in% "./." ~ 0,
	finalmadf %in% "0/0" ~ 0,
	finalmadf %in% "0/1" ~ 1,
	finalmadf %in% "1/1" ~ 2)
finalmadf3 <- matrix(finalmadf2, nrow = v_num)
finalmadf3 <- t(finalmadf3)
pc <- prcomp(finalmadf3)

mod.lfmm <- lfmm_ridge(Y = finalmadf3, X = finalphedf, K = opt$latent)
pv <- lfmm_test(Y = finalmadf3, X = finalphedf, lfmm = mod.lfmm, calibrate = "gif")
pvalues <- pv$calibrated.pvalue
fdrq <- p.adjust(pvalues, method = "BH")

#output
chposf <- paste0(cucvcf@fix[,1], "_", cucvcf@fix[,2])
for (i in c(1:p_num)) {
	pvalues <- pv$calibrated.pvalue[,i]
	fdrq <- p.adjust(pvalues, method = "BH")
	outn <- paste0(opt$outdir,"/",phe[i+1], "_K",opt$latent,"_pvalue.txt")
	outdf <- cbind(chposf, pvalues, fdrq)
	colnames(outdf) <- c("chr_pos", "pvalues", "BH")
	write.table(x = outdf, file = outn, quote = F)
}
