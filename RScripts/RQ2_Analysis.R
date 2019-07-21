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
# 移除混和效应
removeConfoundingEffect<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$commits + indata$years_of_dev)
	return(lm_result)
}
##############################################################
cdata = read.csv(file="RQ2_devBackground_c.csv")

# function templates vs. C-style generics
cdata <- removeOutliers(cdata,2,3)
lm_result_1 <- abs(removeConfoundingEffect(cdata,2)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata,3)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

par(mar=c(3,5,1.3,0.5),mgp=c(3.5,1.5,0),las=1,family="serif",font.lab=2)
x_names <- c("C-style\ngenerics","function\ntemplates")
boxplot(lm_result_1, lm_result_2,
	names=x_names, ylab="# uses", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(lm_result_1),mean(lm_result_2))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p = 0.710, δ = 0.057", cex = 1.1,font = 1))

##############################################################
cdata = read.csv(file="RQ2_devBackground_non_c.csv")

# function templates vs. C-style generics
cdata <- removeOutliers(cdata,2,3)
lm_result_1 <- abs(removeConfoundingEffect(cdata,2)$residuals)
lm_result_2 <- abs(removeConfoundingEffect(cdata,3)$residuals)
wilcox.test(lm_result_1, lm_result_2,paired=TRUE)
cliff.delta(lm_result_1, lm_result_2)

par(mar=c(3,5,1.3,0.5),mgp=c(3.5,1.5,0),las=1,family="serif",font.lab=2)
x_names <- c("C-style\ngenerics","function\ntemplates")
boxplot(lm_result_1, lm_result_2,
	names=x_names, ylab="# uses", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(lm_result_1),mean(lm_result_2))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")
title(main = list("p = 0.004, δ = 0.224", cex = 1.1,font = 1))

