####################################
# 剔除有影响的outlier
removeOutliers<-function(indata,col1,col2){
	while(1){
		lm_result <- lm(indata[,col1] ~ indata[,col2])
		d <- cooks.distance(lm_result)
		newdata <- cbind(indata, d)
		#只保留cook's distance < 1的数据
		filtereddata <- newdata[d<1,]
		if(nrow(filtereddata) == nrow(indata)){
			break
		} else {
			indata <- filtereddata[,-11]
		}
	}
	return(indata)
}
#移除混和效应
removeConfoundingEffect<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$sloc + indata$dev_num + indata$proj_age)
	return(lm_result)
}

####################################
# 读取数据
confd = read.csv(file="BasicInfo_0.csv")
proj_names <- confd$project.name
pvalues <- c()
rhos <- c()
for (proj_name in proj_names){
	filename <- paste("RQ4/",proj_name,"_RQ4.csv",sep="",collapse="")
	cdata = read.csv(file=filename)
	print(proj_name)
	crtp <- cdata[,5]
	print(crtp)
	# 移除混和效应
	cdata <- removeOutliers(cdata,5,6)
	lm_result_1 <- abs(removeConfoundingEffect(cdata,5)$residuals)
	lm_result_2 <- abs(removeConfoundingEffect(cdata,6)$residuals)
	# 相关性分析
	result = cor.test(lm_result_1, lm_result_2, method="spearman")
	print(result)
	pvalues <- c(pvalues,result$p.value)
	rhos <- c(rhos,result$estimate)
}
pvalues_estb <- pvalues[1:25]
pvalues_BH_estb <- p.adjust(pvalues_estb, method = "BH", n = length(pvalues_estb))
pvalues_rcnt <- pvalues[26:50]
pvalues_BH_rcnt <- p.adjust(pvalues_rcnt, method = "BH", n = length(pvalues_rcnt))
pvalues_BH <- c(pvalues_BH_estb,pvalues_BH_rcnt)
output_data <- data.frame(proj_names,pvalues_BH,rhos)
output_data <- data.frame(proj_names,pvalues,rhos)
write.csv(output_data, file = "RQ4.csv")
