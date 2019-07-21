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
# 读取数据
IVdata = read.csv(file="NewTempFeatures_OldSubs.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-8]
cdata_estb <- cdata[-c(26:50),]
cdata_rcnt <- cdata[-c(1:25),]

# established projects的执行结果
# variadic function templates vs. old substitutes
cdata_estb_temp <- removeOutliers(cdata_estb,2,5)
lm_result_vft_estb <- removeConfoundingEffect(cdata_estb_temp,2)
lm_result_osvft_estb <- removeConfoundingEffect(cdata_estb_temp,5)
# variadic function templates vs. old substitutes, established projects
wilcox.test(abs(lm_result_vft_estb$residuals), abs(lm_result_osvft_estb$residuals),paired=TRUE)
cliff.delta(abs(lm_result_vft_estb$residuals), abs(lm_result_osvft_estb$residuals))

# variadic class templates vs. old substitutes
IVdata = read.csv(file="NewTempFeatures_OldSubs.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-8]
cdata_estb <- cdata[-c(26:50),]
cdata_estb_temp <- removeOutliers(cdata_estb,3,6)
lm_result_vct_estb <- removeConfoundingEffect(cdata_estb_temp,3)
lm_result_osvct_estb <- removeConfoundingEffect(cdata_estb_temp,6)
# variadic function templates vs. old substitutes, established projects
wilcox.test(abs(lm_result_vct_estb$residuals), abs(lm_result_osvct_estb$residuals),paired=TRUE)
cliff.delta(abs(lm_result_vct_estb$residuals), abs(lm_result_osvct_estb$residuals))

# alias class templates vs. old substitutes
IVdata = read.csv(file="NewTempFeatures_OldSubs.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-8]
cdata_estb <- cdata[-c(26:50),]
removeOutliers(cdata_estb,4,7)
lm_result_act_estb <- removeConfoundingEffect(cdata_estb_temp,4)
lm_result_osact_estb <- removeConfoundingEffect(cdata_estb_temp,7)
# alias function templates vs. old substitutes, established projects
wilcox.test(abs(lm_result_act_estb$residuals), abs(lm_result_osact_estb$residuals),paired=TRUE)
cliff.delta(abs(lm_result_act_estb$residuals), abs(lm_result_osact_estb$residuals))

# recent projects的执行结果
# variadic function templates vs. old substitutes
cdata_rcnt_temp <- removeOutliers(cdata_rcnt,2,5)
lm_result_vft_rcnt <- removeConfoundingEffect(cdata_rcnt_temp,2)
lm_result_osvft_rcnt <- removeConfoundingEffect(cdata_rcnt_temp,5)
# variadic function templates vs. old substitutes, established projects
wilcox.test(abs(lm_result_vft_rcnt$residuals), abs(lm_result_osvft_rcnt$residuals),paired=TRUE)
cliff.delta(abs(lm_result_vft_rcnt$residuals), abs(lm_result_osvft_rcnt$residuals))

# variadic class templates vs. old substitutes
IVdata = read.csv(file="NewTempFeatures_OldSubs.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-8]
cdata_rcnt <- cdata[-c(1:25),]
cdata_rcnt_temp <- removeOutliers(cdata_rcnt,3,6)
lm_result_vct_rcnt <- removeConfoundingEffect(cdata_rcnt_temp,3)
lm_result_osvct_rcnt <- removeConfoundingEffect(cdata_rcnt_temp,6)
# variadic function templates vs. old substitutes, established projects
wilcox.test(abs(lm_result_vct_rcnt$residuals), abs(lm_result_osvct_rcnt$residuals),paired=TRUE)
cliff.delta(abs(lm_result_vct_rcnt$residuals), abs(lm_result_osvct_rcnt$residuals))

# alias class templates vs. old substitutes
IVdata = read.csv(file="NewTempFeatures_OldSubs.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-8]
cdata_rcnt <- cdata[-c(1:25),]
cdata_rcnt_temp <- removeOutliers(cdata_rcnt,4,7)
lm_result_act_rcnt <- removeConfoundingEffect(cdata_rcnt_temp,4)
lm_result_osact_rcnt <- removeConfoundingEffect(cdata_rcnt_temp,7)
# alias function templates vs. old substitutes, established projects
wilcox.test(abs(lm_result_act_rcnt$residuals), abs(lm_result_osact_rcnt$residuals),paired=TRUE)
cliff.delta(abs(lm_result_act_rcnt$residuals), abs(lm_result_osact_rcnt$residuals))


par(mar=c(3,6,1.1,0.5),mgp=c(3.5,1.7,0),las=1,family="serif",font.lab=2)
x_names <- c("VFT","old substitutes")
boxplot(lm_result_vft_rcnt$residuals, lm_result_osvft_rcnt$residuals,
	names=x_names, ylab="total number", pars = (list(boxwex=0.5,cex.axis=1.2,cex.lab=1.5)))
means <- c(mean(lm_result_vft_rcnt$residuals),mean(lm_result_osvft_rcnt$residuals))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")

p_values = c(0.000003815,0.00006366,0.0000000596)
p.adjust(p_values, method = "BH", n = length(p_values))

p_values = c(0.9563,0.0000002384,0.005581)
p.adjust(p_values, method = "BH", n = length(p_values))
