####################################
# 剔除有影响的outlier
removeOutliers<-function(indata){
	while(1){
		lm_result <- lm(explicit_decls ~ auto_decls, data = indata)
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

#移除混和效应
removeConfoundingEffect<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$SLOC + indata$developers + indata$age)
	return(lm_result)
}

####################################
# 读取数据
IVdata = read.csv(file="AutoDecl_ExplicitDecl.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-4]
cdata_estb <- cdata[-c(26:50),]
cdata_rcnt <- cdata[-c(1:25),]

# established projects
# 剔除outlier
cdata_estb<-removeOutliers(cdata_estb)
# 移除混和效应
lm_result_1 <- removeConfoundingEffect(cdata_estb,2)
lm_result_2 <- removeConfoundingEffect(cdata_estb,3)
# auto declarations vs. explicit declarations
wilcox.test(abs(lm_result_1$residuals),abs(lm_result_2$residuals),paired=TRUE)
cliff.delta(abs(lm_result_1$residuals),abs(lm_result_2$residuals))

par(mar=c(3,6,1.3,0.5),mgp=c(4,1,0),las=1,family="serif",font.lab=2)
x_names <- c("implicit","explicit")
boxplot(abs(lm_result_1$residuals),abs(lm_result_2$residuals),
	names=x_names, ylab="# type declarations", pars = (list(boxwex=0.5,cex.axis=1.2,cex.lab=1.5)))
means <- c(mean(abs(lm_result_1$residuals)),mean(abs(lm_result_2$residuals)))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p < 0.001, δ = -1", cex = 1.1,font = 1))


# recent projects
# 剔除outlier
cdata_rcnt<-removeOutliers(cdata_rcnt)
# 移除混和效应
lm_result_1 <- removeConfoundingEffect(cdata_rcnt,2)
lm_result_2 <- removeConfoundingEffect(cdata_rcnt,3)
# auto declarations vs. explicit declarations
wilcox.test(abs(lm_result_1$residuals),abs(lm_result_2$residuals),paired=TRUE)
cliff.delta(abs(lm_result_1$residuals),abs(lm_result_2$residuals))

par(mar=c(3,6,1.3,0.5),mgp=c(4,1,0),las=1,family="serif",font.lab=2)
x_names <- c("implicit","explicit")
boxplot(abs(lm_result_1$residuals),abs(lm_result_2$residuals),
	names=x_names, ylab="# type declarations", pars = (list(boxwex=0.5,cex.axis=1.2,cex.lab=1.5)))
means <- c(mean(abs(lm_result_1$residuals)),mean(abs(lm_result_2$residuals)))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p < 0.001, δ = -0.969", cex = 1.1,font = 1))
