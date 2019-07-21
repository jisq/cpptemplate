##############################################################
cdata = read.csv(file="RQ1_percentage.csv")

cdata <- cdata * 100

par(mar=c(3,5,1.3,0.5),mgp=c(3.5,1.5,0),las=1,family="serif",font.lab=2)
x_names <- c("established\nsystems","recent\nsystems")
boxplot(cdata$estb_function_temp, cdata$rcnt_function_temp,
	names=x_names, ylab="% function templates", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(cdata$estb_function_temp),mean(cdata$rcnt_function_temp))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")

par(mar=c(3,5,1.3,0.5),mgp=c(3.5,1.5,0),las=1,family="serif",font.lab=2)
x_names <- c("established\nsystems","recent\nsystems")
boxplot(cdata$estb_class_temp, cdata$rcnt_class_temp,
	names=x_names, ylab="% class templates", pars = (list(boxwex=0.5,cex.axis=1,cex.lab=1.3)))
means <- c(mean(cdata$estb_class_temp),mean(cdata$rcnt_class_temp))
mean_cur <- c(means[1],means[2])
points(mean_cur,pch=0,lwd=3,col="red")