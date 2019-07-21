####################################
# 剔除有影响的outlier
removeOutliers<-function(indata){
	while(1){
		lm_result <- lm(derivations_lib ~ derivations_user_def, data = indata)
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
IVdata = read.csv(file="RQ7.csv")
confd = read.csv(file="BasicInfo_0.csv")
cdata <- cbind(IVdata,confd)
cdata <- cdata[,-4]
cdata_estb <- cdata[-c(26:50),]
cdata_rcnt <- cdata[-c(1:25),]

# established projects
cdata_estb <- removeOutliers(cdata_estb)
# 移除混和效应
lm_result_1 <- removeConfoundingEffect(cdata_estb,2)
lm_result_2 <- removeConfoundingEffect(cdata_estb,3)
# derivations from STL vs. derivations from userdef templates
wilcox.test(abs(lm_result_1$residuals), abs(lm_result_2$residuals),paired=TRUE,alternative="less")
cliff.delta(abs(lm_result_1$residuals), abs(lm_result_2$residuals))

par(mar=c(3,5,1.3,0.5),mgp=c(3.5,1.7,0),las=1,family="serif",font.lab=2)
x_names <- c("STL\ntypes","user-defined\nclass templates")
boxplot(abs(lm_result_1$residuals), abs(lm_result_2$residuals),
	names=x_names, ylab="# derivations", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(abs(lm_result_1$residuals)),mean(abs(lm_result_2$residuals)))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p < 0.001, δ = -0.815", cex = 1.1,font = 1))

# recent projects
cdata_rcnt <- removeOutliers(cdata_rcnt)
# 移除混和效应
lm_result_1 <- removeConfoundingEffect(cdata_rcnt,2)
lm_result_2 <- removeConfoundingEffect(cdata_rcnt,3)
# derivations from STL vs. derivations from userdef templates
wilcox.test(abs(lm_result_1$residuals), abs(lm_result_2$residuals),paired=TRUE,alternative="less")
cliff.delta(abs(lm_result_1$residuals), abs(lm_result_2$residuals))

par(mar=c(3,5,1.3,0.5),mgp=c(3.5,1.7,0),las=1,family="serif",font.lab=2)
x_names <- c("STL\ntypes","user-defined\nclass templates")
boxplot(abs(lm_result_1$residuals), abs(lm_result_2$residuals),
	names=x_names, ylab="# derivations", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(abs(lm_result_1$residuals)),mean(abs(lm_result_2$residuals)))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p < 0.001, δ = -0.635", cex = 1.1,font = 1))

