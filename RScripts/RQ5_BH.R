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
# BH adjust for p-values
pvalues1_estb <- p_values_1[1:25]
pvalues1_BH_estb <- p.adjust(pvalues1_estb, method = "BH", n = length(pvalues1_estb))
pvalues1_rcnt <- p_values_1[26:50]
pvalues1_BH_rcnt <- p.adjust(pvalues1_rcnt, method = "BH", n = length(pvalues1_rcnt))
pvalues1_BH <- c(pvalues1_BH_estb,pvalues1_BH_rcnt)

pvalues2_estb <- p_values_2[1:25]
pvalues2_BH_estb <- p.adjust(pvalues2_estb, method = "BH", n = length(pvalues2_estb))
pvalues2_rcnt <- p_values_2[26:50]
pvalues2_BH_rcnt <- p.adjust(pvalues2_rcnt, method = "BH", n = length(pvalues2_rcnt))
pvalues2_BH <- c(pvalues2_BH_estb,pvalues2_BH_rcnt)

pvalues3_estb <- p_values_3[1:25]
pvalues3_BH_estb <- p.adjust(pvalues3_estb, method = "BH", n = length(pvalues3_estb))
pvalues3_rcnt <- p_values_3[26:50]
pvalues3_BH_rcnt <- p.adjust(pvalues3_rcnt, method = "BH", n = length(pvalues3_rcnt))
pvalues3_BH <- c(pvalues3_BH_estb,pvalues3_BH_rcnt)

pvalues4_estb <- p_values_4[1:25]
pvalues4_BH_estb <- p.adjust(pvalues4_estb, method = "BH", n = length(pvalues4_estb))
pvalues4_rcnt <- p_values_4[26:50]
pvalues4_BH_rcnt <- p.adjust(pvalues4_rcnt, method = "BH", n = length(pvalues4_rcnt))
pvalues4_BH <- c(pvalues4_BH_estb,pvalues4_BH_rcnt)

output_data <- data.frame(proj_names,pvalues1_BH,pvalues2_BH,pvalues3_BH,pvalues4_BH)
write.csv(output_data, file = "RQ5_BH.csv")

