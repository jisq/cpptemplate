
#移除混和效应
removeConfoundingEffect_estb<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$estb_SLOC + indata$estb_developers + indata$estb_age)
	return(lm_result)
}

removeConfoundingEffect_rcnt<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$rcnt_SLOC + indata$rcnt_developers + indata$rcnt_age)
	return(lm_result)
}

####################################
# 读取数据
IVdata = read.csv(file="TempDefAndUse_estb_rcnt.csv")
confd = read.csv(file="BasicInfo_0_estb_rcnt.csv")
cdata <- cbind(IVdata,confd)
#移除混和效应
lm_result_tempdef_estb <- removeConfoundingEffect_estb(cdata,2)
lm_result_tempuse_estb <- removeConfoundingEffect_estb(cdata,3)
lm_result_tempdef_rcnt <- removeConfoundingEffect_rcnt(cdata,5)
lm_result_tempuse_rcnt <- removeConfoundingEffect_rcnt(cdata,6)

# established projects vs. recent projects, template definitions
residuals_tempdef_estb <- abs(lm_result_tempdef_estb$residuals)
residuals_tempdef_rcnt <- abs(lm_result_tempdef_rcnt$residuals)
wilcox.test(residuals_tempdef_estb, residuals_tempdef_rcnt)
cliff.delta(residuals_tempdef_estb, residuals_tempdef_rcnt)

# established projects vs. recent projects, template uses
residuals_tempuse_estb <- abs(lm_result_tempuse_estb$residuals)
residuals_tempuse_rcnt <- abs(lm_result_tempuse_rcnt$residuals)
wilcox.test(residuals_tempuse_estb, residuals_tempuse_rcnt)
cliff.delta(residuals_tempuse_estb, residuals_tempuse_rcnt)

par(mar=c(3,6,1.3,0.5),mgp=c(3.5,1.5,0),family="serif",font.lab=2)
x_names <- c("established\nsystems","recent\nsystems")
boxplot(residuals_tempdef_estb, residuals_tempdef_rcnt,
	names=x_names, ylab="# template definitions", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(residuals_tempdef_estb),mean(residuals_tempdef_rcnt))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p = 0.152, δ = 0.238", cex = 1.1,font = 1))

par(mar=c(3,6,1.3,0.5),mgp=c(4,1.5,0),las=1,family="serif",font.lab=2)
x_names <- c("established\nsystems","recent\nsystems")
boxplot(residuals_tempuse_estb, residuals_tempuse_rcnt,
	names=x_names, ylab="# template uses", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(residuals_tempuse_estb),mean(residuals_tempuse_rcnt))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p < 0.001, δ = 0.664", cex = 1.1,font = 1))

