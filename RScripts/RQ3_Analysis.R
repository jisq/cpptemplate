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
	lm_result <- lm(indata[,i] ~ indata$commits + indata$years_of_dev)
	return(lm_result)
}
###########################################################################
cdata = read.csv(file="RQ3_devBackground_javacsharp.csv")

# class templates vs. deep inheritance hierarchies
cdata <- removeOutliers(cdata,2,3)
lm_result_1 <- abs(removeConfoundingEffect(cdata,2)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata,3)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

###########################################################################
cdata = read.csv(file="RQ3_devBackground_non_javacsharp.csv")

# class templates vs. deep inheritance hierarchies
cdata <- removeOutliers(cdata,2,3)
lm_result_1 <- abs(removeConfoundingEffect(cdata,2)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata,3)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)
