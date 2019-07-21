library("methods")
library("poweRlaw")
####################################
# 移除混和效应
removeConfoundingEffect<-function(indata,i){
	lm_result <- lm(indata[,i] ~ indata$commits + indata$years)
	return(lm_result)
}

# power-law analysis
powerLawAnalysis<-function(lm_result){
	msg <- tryCatch({
		#Continuous power law objects take vectors as inputs
		m_pl = conpl$new(lm_result)
		#estimate the lower-bound
		est_pl = estimate_xmin(m_pl)
		m_pl$setXmin(est_pl)
		#pars_pl = estimate_pars(m_pl)
		bs_p = bootstrap_p(m_pl,threads=10)
		return(bs_p$p)
  	}, error = function(e) {
		return(-1)
  	})
}

####################################
p_values_1 <- c()
p_values_2 <- c()
p_values_3 <- c()
p_values_4 <- c()
# 读取数据
confd = read.csv(file="BasicInfo_0.csv")
proj_names <- confd$project.name
for (proj_name in proj_names){
	filename <- paste("RQ5/",proj_name,"_RQ5.csv",sep="",collapse="")
	cdata = read.csv(file=filename)
	print(proj_name)
	# 移除混和效应
	lm_result_1 <- abs(removeConfoundingEffect(cdata,4)$residuals)
	lm_result_2 <- abs(removeConfoundingEffect(cdata,5)$residuals)
	lm_result_3 <- abs(removeConfoundingEffect(cdata,6)$residuals)
	lm_result_4 <- abs(removeConfoundingEffect(cdata,7)$residuals)
	# power-law analysis
	p_values_1 <- c(p_values_1,powerLawAnalysis(lm_result_1))
	p_values_2 <- c(p_values_2,powerLawAnalysis(lm_result_2))
	p_values_3 <- c(p_values_3,powerLawAnalysis(lm_result_3))
	p_values_4 <- c(p_values_4,powerLawAnalysis(lm_result_4))
}
output_data <- data.frame(proj_names,p_values_1,p_values_2,p_values_3,p_values_4)
write.csv(output_data, file = "RQ5.csv")

