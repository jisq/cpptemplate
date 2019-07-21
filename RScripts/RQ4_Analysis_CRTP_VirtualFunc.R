####################################
# 剔除有影响的outlier
removeOutliers<-function(indata,col1,col2){
	while(1){
		lm_result <- lm(indata[,col1]~indata[,col2])
		d <- cooks.distance(lm_result)
		newdata <- cbind(indata, d)
		#只保留cook's distance < 1的数据
		filtereddata <- newdata[d<1,]
		if(nrow(filtereddata) == nrow(indata)){
			break
		} else {
			indata <- filtereddata[,-7]
		}
	}
	return(indata)
}

# 移除混和效应
removeConfoundingEffect<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$SLOC + indata$developers + indata$age)
	return(lm_result)
}

####################################
# 读取数据
IVdata = read.csv(file="RQ4_CRTP_VirtualFunc.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-4]
cdata_estb <- cdata[-c(26:50),]
cdata_rcnt <- cdata[-c(1:25),]

# established projects
cdata_estb <- removeOutliers(cdata_estb,2,3)
# 移除混和效应
lm_result_1 <- removeConfoundingEffect(cdata_estb,2)
lm_result_2 <- removeConfoundingEffect(cdata_estb,3)
# function templates vs. c-style generics
wilcox.test(abs(lm_result_1$residuals), abs(lm_result_2$residuals),paired=TRUE)
cliff.delta(abs(lm_result_1$residuals), abs(lm_result_2$residuals))

# recent projects
cdata_rcnt <- removeOutliers(cdata_rcnt,2,3)
# 移除混和效应
lm_result_1 <- removeConfoundingEffect(cdata_rcnt,2)
lm_result_2 <- removeConfoundingEffect(cdata_rcnt,3)
# function templates vs. c-style generics
wilcox.test(abs(lm_result_1$residuals), abs(lm_result_2$residuals),paired=TRUE)
cliff.delta(abs(lm_result_1$residuals), abs(lm_result_2$residuals))

# all projects
cdata <- removeOutliers(cdata,2,3)
# 移除混和效应
lm_result_1 <- removeConfoundingEffect(cdata,2)
lm_result_2 <- removeConfoundingEffect(cdata,3)
# function templates vs. c-style generics
wilcox.test(abs(lm_result_1$residuals), abs(lm_result_2$residuals),paired=TRUE)
cliff.delta(abs(lm_result_1$residuals), abs(lm_result_2$residuals))

