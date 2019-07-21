####################################
#移除混和效应
removeConfoundingEffect<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$SLOC + indata$developers + indata$age)
	return(lm_result)
}

####################################
# 读取数据
IVdata = read.csv(file="TempDefAndUse.csv")
confd = read.csv(file="BasicInfo_0_category.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-4]

category_names <- c("Audio & Video", 
"Business & Enterprise", 
"Communications",
"Development",
"Home & Education",
"Games",
"Graphics",
"Science & Engineering",
"Security & Utilities",
"System Administration")

diff_magnitude_level <- c("negligible","small","moderate","large")

categories <- length(category_names)
comp_category_names <- c()
pvalues_tempdef <- c()
deltas_tempdef <- c()
deltas_mag_tempdef <- c()
pvalues_tempuse <- c()
deltas_tempuse <- c()
deltas_mag_tempuse <- c()

#pvalues_tempdef <- matrix(nrow=10,ncol=10)
#pvalues_tempdef_primary <- c()
#deltas_tempdef <- matrix(nrow=10,ncol=10)
#deltas_mag_tempdef <- matrix(nrow=10,ncol=10)
#pvalues_tempuse <- matrix(nrow=10,ncol=10)
#pvalues_tempuse_primary <- c()
#deltas_tempuse <- matrix(nrow=10,ncol=10)
#deltas_mag_tempuse <- matrix(nrow=10,ncol=10)
for(i in 1:(categories-1)){
	for(j in (i+1):categories){
		
		print(paste(i,":",j))
	
		cdata1 <- cdata[which(cdata$category==category_names[i]),]
		cdata2 <- cdata[which(cdata$category==category_names[j]),]

		comp_category_names_str <- paste(category_names[i],"vs.",category_names[j])
		comp_category_names <- c(comp_category_names,comp_category_names_str)

		# template definition
		lm_result_1 <- abs(removeConfoundingEffect(cdata1,2)$residuals)
		lm_result_2 <- abs(removeConfoundingEffect(cdata2,2)$residuals)
		diff <- wilcox.test(lm_result_1, lm_result_2)
		delta <- cliff.delta(lm_result_1, lm_result_2)
		pvalues_tempdef <- c(pvalues_tempdef,diff$p.value)
		deltas_tempdef <- c(deltas_tempdef,delta$estimate)
		deltas_mag_tempdef <- c(deltas_mag_tempdef,diff_magnitude_level[delta$magnitude])

		# template use
		lm_result_1 <- abs(removeConfoundingEffect(cdata1,3)$residuals)
		lm_result_2 <- abs(removeConfoundingEffect(cdata2,3)$residuals)
		diff <- wilcox.test(lm_result_1, lm_result_2)
		delta <- cliff.delta(lm_result_1, lm_result_2)
		pvalues_tempuse <- c(pvalues_tempuse,diff$p.value)
		deltas_tempuse <- c(deltas_tempuse,delta$estimate)
		deltas_mag_tempuse <- c(deltas_mag_tempuse,diff_magnitude_level[delta$magnitude])
	}
}

pvalues_tempdef_BH <- p.adjust(pvalues_tempdef, method = "BH", n = length(pvalues_tempdef))
pvalues_tempuse_BH <- p.adjust(pvalues_tempuse, method = "BH", n = length(pvalues_tempuse))

output_data <- data.frame(comp_category_names,pvalues_tempdef_BH,deltas_tempdef,deltas_mag_tempdef,
pvalues_tempuse_BH,deltas_tempuse,deltas_mag_tempuse)
write.csv(output_data, file = "BasicStat_category.csv")
