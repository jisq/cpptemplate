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
			indata <- filtereddata[,-13]
		}
	}
	return(indata)
}
# 移除混和效应
removeConfoundingEffect<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$SLOC + indata$developers + indata$age)
	return(lm_result)
}
###########################################################################
IVdata = read.csv(file="RQ5_devBackground.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-10]
cdata_estb <- cdata[-c(26:50),]
cdata_rcnt <- cdata[-c(1:25),]

# class templates vs. deep inheritance hierarchies (established projects)
cdata_estb <- removeOutliers(cdata_estb,2,3)
lm_result_1 <- abs(removeConfoundingEffect(cdata_estb,2)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata_estb,3)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

# class templates vs. deep inheritance hierarchies (recent projects)
cdata_rcnt <- removeOutliers(cdata_rcnt,2,3)
lm_result_1 <- abs(removeConfoundingEffect(cdata_rcnt,2)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata_rcnt,3)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

# class templates vs. deep inheritance hierarchies (all projects)
cdata <- removeOutliers(cdata,2,3)
lm_result_1 <- abs(removeConfoundingEffect(cdata,2)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata,3)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)
###########################################################################
IVdata = read.csv(file="RQ5_devBackground.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-10]
cdata_estb <- cdata[-c(26:50),]
cdata_rcnt <- cdata[-c(1:25),]

# class templates vs. deep inheritance hierarchies (established projects)
cdata_estb <- removeOutliers(cdata_estb,4,5)
lm_result_1 <- abs(removeConfoundingEffect(cdata_estb,4)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata_estb,5)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

# class templates vs. deep inheritance hierarchies (recent projects)
cdata_rcnt <- removeOutliers(cdata_rcnt,4,5)
lm_result_1 <- abs(removeConfoundingEffect(cdata_rcnt,4)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata_rcnt,5)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

# class templates vs. deep inheritance hierarchies (all projects)
cdata <- removeOutliers(cdata,4,5)
lm_result_1 <- abs(removeConfoundingEffect(cdata,4)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata,5)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)
###########################################################################
IVdata = read.csv(file="RQ5_devBackground.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-10]
cdata_estb <- cdata[-c(26:50),]
cdata_rcnt <- cdata[-c(1:25),]

# class templates vs. deep inheritance hierarchies (established projects)
cdata_estb <- removeOutliers(cdata_estb,6,7)
lm_result_1 <- abs(removeConfoundingEffect(cdata_estb,6)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata_estb,7)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

# class templates vs. deep inheritance hierarchies (recent projects)
cdata_rcnt <- removeOutliers(cdata_rcnt,6,7)
lm_result_1 <- abs(removeConfoundingEffect(cdata_rcnt,6)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata_rcnt,7)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

# class templates vs. deep inheritance hierarchies (all projects)
cdata <- removeOutliers(cdata,6,7)
lm_result_1 <- abs(removeConfoundingEffect(cdata,6)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata,7)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)
###########################################################################
IVdata = read.csv(file="RQ5_devBackground.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-10]
cdata_estb <- cdata[-c(26:50),]
cdata_rcnt <- cdata[-c(1:25),]

# class templates vs. deep inheritance hierarchies (established projects)
cdata_estb <- removeOutliers(cdata_estb,8,9)
lm_result_1 <- abs(removeConfoundingEffect(cdata_estb,8)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata_estb,9)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

# class templates vs. deep inheritance hierarchies (recent projects)
cdata_rcnt <- removeOutliers(cdata_rcnt,8,9)
lm_result_1 <- abs(removeConfoundingEffect(cdata_rcnt,8)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata_rcnt,9)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

# class templates vs. deep inheritance hierarchies (all projects)
cdata <- removeOutliers(cdata,8,9)
lm_result_1 <- abs(removeConfoundingEffect(cdata,8)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata,9)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)