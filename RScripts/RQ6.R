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
	lm_result <- lm(indata[,i] ~ indata$SLOC + indata$developers + indata$age)
	return(lm_result)
}

####################################
# established projects
p_values_estb <- c()
for(i in 2:6){
	for(j in (i+1):7){
		# 读取数据
		IVdata = read.csv(file="RQ6.csv")
		confd = read.csv(file="BasicInfo_0.csv")
		cdata <- cbind(IVdata,confd)
		cdata <- cdata[,-8]
		cdata_estb <- cdata[-c(26:50),]
		cdata_estb <- removeOutliers(cdata_estb,i,j)
		lm_result_1 <- abs(removeConfoundingEffect(cdata_estb,i)$residuals)
		lm_result_2 <- abs(removeConfoundingEffect(cdata_estb,j)$residuals)
		diff <- wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
		delta <- cliff.delta(lm_result_1, lm_result_2)
print(i)
print(j)
		print(diff$p.value)
p_values_estb<-c(p_values_estb,diff$p.value)
		print(delta$estimate)
		print(delta$magnitude)
	}
}
p.adjust(p_values_estb, method = "BH", n = length(p_values_estb))

####################################
# recent projects
p_values_rcnt <- c()
for(i in 2:6){
	for(j in (i+1):7){
		# 读取数据
		IVdata = read.csv(file="RQ6.csv")
		confd = read.csv(file="BasicInfo_0.csv")
		cdata <- cbind(IVdata,confd)
		cdata <- cdata[,-8]
		cdata_estb <- cdata[-c(1:25),]
		cdata_estb <- removeOutliers(cdata_estb,i,j)
		lm_result_1 <- abs(removeConfoundingEffect(cdata_estb,i)$residuals)
		lm_result_2 <- abs(removeConfoundingEffect(cdata_estb,j)$residuals)
		diff <- wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
		delta <- cliff.delta(lm_result_1, lm_result_2)
print(i)
print(j)
		print(diff$p.value)
p_values_rcnt<-c(p_values_rcnt,diff$p.value)
		print(delta$estimate)
		print(delta$magnitude)
	}
}
p.adjust(p_values_rcnt, method = "BH", n = length(p_values_rcnt))

