#移除混和效应
removeConfoundingEffect1<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$sloc + indata$dev_num + indata$proj_age + indata$funcs_with_void_ptr)
	return(lm_result)
}

removeConfoundingEffect2<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$sloc + indata$dev_num + indata$proj_age + indata$GFLM_num)
	return(lm_result)
}

####################################
# 读取数据
confd = read.csv(file="BasicInfo_0.csv")
proj_names <- confd$project.name
p_value1 <- c()
rho1 <- c()
p_value2 <- c()
rho2 <- c()
for (proj_name in proj_names){
	filename <- paste("RQ2/",proj_name,"_RQ2.csv",sep="",collapse="")
	cdata = read.csv(file=filename)
	print(proj_name)
	# 移除混和效应（function templates vs. GFLM）
	lm_result_1 <- abs(removeConfoundingEffect1(cdata,5)$residuals)
	lm_result_2 <- abs(removeConfoundingEffect1(cdata,6)$residuals)
	# 相关性分析（function templates vs. GFLM）
	result = cor.test(lm_result_1, lm_result_2, method="spearman")
	print(result)
	p_value1 <- c(p_value1,result$p.value)
	rho1 <- c(rho1,result$estimate)

	funcs_with_void_ptr <- cdata[,7]
	# 移除混和效应（function templates vs. functions implemented with void*）
	lm_result_1 <- abs(removeConfoundingEffect2(cdata,5)$residuals)
	lm_result_2 <- abs(removeConfoundingEffect2(cdata,7)$residuals)
	# 相关性分析（function templates vs. functions implemented with void*）
	result = cor.test(lm_result_1, lm_result_2, method="spearman")
	print(result)
	p_value2 <- c(p_value2,result$p.value)
	rho2 <- c(rho2,result$estimate)
}
# BH-adjust for p-values
pvalues_estb <- p_value1[1:25]
pvalues_BH_estb <- p.adjust(pvalues_estb, method = "BH", n = length(pvalues_estb))
pvalues_rcnt <- p_value1[26:50]
pvalues_BH_rcnt <- p.adjust(pvalues_rcnt, method = "BH", n = length(pvalues_rcnt))
pvalues1_BH <- c(pvalues_BH_estb,pvalues_BH_rcnt)
pvalues_estb <- p_value2[1:25]
pvalues_BH_estb <- p.adjust(pvalues_estb, method = "BH", n = length(pvalues_estb))
pvalues_rcnt <- p_value2[26:50]
pvalues_BH_rcnt <- p.adjust(pvalues_rcnt, method = "BH", n = length(pvalues_rcnt))
pvalues2_BH <- c(pvalues_BH_estb,pvalues_BH_rcnt)
output_data <- data.frame(proj_names,pvalues1_BH,rho1,pvalues2_BH,rho2)
write.csv(output_data, file = "RQ2.csv")
