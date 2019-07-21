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
			indata <- filtereddata[,-8]
		}
	}
	return(indata)
}

# 移除混和效应
removeConfoundingEffect<-function(indata,i,j){
	lm_result <- lm(indata[,i] ~ indata$SLOC + indata$developers + indata$age + indata[,j])
	return(lm_result)
}

####################################
# 读取数据
IVdata = read.csv(file="RQ2_FuncTemp_Cgenerics_GFLM_FIVP.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-5]
cdata_estb <- cdata[-c(26:50),]
cdata_rcnt <- cdata[-c(1:25),]

# established projects
cdata_estb <- removeOutliers(cdata_estb,2,3)
# function templates vs. GFLM
lm_result_1 <- removeConfoundingEffect(cdata_estb,2,4)
lm_result_2 <- removeConfoundingEffect(cdata_estb,3,4)
wilcox.test(abs(lm_result_1$residuals), abs(lm_result_2$residuals),paired=TRUE)
cliff.delta(abs(lm_result_1$residuals), abs(lm_result_2$residuals))
par(mar=c(3,5.5,1.3,0.5),mgp=c(4,1.5,0),las=1,family="serif",font.lab=2)
x_names <- c("function\ntemplates","GFLM")
boxplot(abs(lm_result_1$residuals), abs(lm_result_2$residuals),
	names=x_names, ylab="Total number", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(abs(lm_result_1$residuals)),mean(abs(lm_result_2$residuals)))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p = 0.008, δ = 0.483", cex = 1.1,font = 1))

# function templates vs. FIVP
lm_result_1 <- removeConfoundingEffect(cdata_estb,2,3)
lm_result_2 <- removeConfoundingEffect(cdata_estb,4,3)
wilcox.test(abs(lm_result_1$residuals), abs(lm_result_2$residuals),paired=TRUE)
cliff.delta(abs(lm_result_1$residuals), abs(lm_result_2$residuals))
par(mar=c(3,5.5,1.3,0.5),mgp=c(4,1.5,0),las=1,family="serif",font.lab=2)
x_names <- c("function\ntemplates","FIVP")
boxplot(abs(lm_result_1$residuals), abs(lm_result_2$residuals),
	names=x_names, ylab="Total number", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(abs(lm_result_1$residuals)),mean(abs(lm_result_2$residuals)))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p = 0.037, δ = -0.177", cex = 1.1,font = 1))

# recent projects
cdata_rcnt <- removeOutliers(cdata_rcnt,2,3)
# function templates vs. GFLM
lm_result_1 <- removeConfoundingEffect(cdata_rcnt,2,4)
lm_result_2 <- removeConfoundingEffect(cdata_rcnt,3,4)
wilcox.test(abs(lm_result_1$residuals), abs(lm_result_2$residuals),paired=TRUE)
cliff.delta(abs(lm_result_1$residuals), abs(lm_result_2$residuals))
par(mar=c(3,5.5,1.3,0.5),mgp=c(4,1.5,0),las=1,family="serif",font.lab=2)
x_names <- c("function\ntemplates","GFLM")
boxplot(abs(lm_result_1$residuals), abs(lm_result_2$residuals),
	names=x_names, ylab="Total number", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(abs(lm_result_1$residuals)),mean(abs(lm_result_2$residuals)))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p < 0.005, δ = 0.939", cex = 1.1,font = 1))

# function templates vs. FIVP
lm_result_1 <- removeConfoundingEffect(cdata_rcnt,2,3)
lm_result_2 <- removeConfoundingEffect(cdata_rcnt,4,3)
wilcox.test(abs(lm_result_1$residuals), abs(lm_result_2$residuals),paired=TRUE)
cliff.delta(abs(lm_result_1$residuals), abs(lm_result_2$residuals))
par(mar=c(3,5.5,1.3,0.5),mgp=c(4,1.5,0),las=1,family="serif",font.lab=2)
x_names <- c("function\ntemplates","FIVP")
boxplot(abs(lm_result_1$residuals), abs(lm_result_2$residuals),
	names=x_names, ylab="Total number", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(abs(lm_result_1$residuals)),mean(abs(lm_result_2$residuals)))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p = 0.048, δ = 0.366", cex = 1.1,font = 1))


