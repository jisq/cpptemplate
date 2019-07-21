####################################
# 读取数据
confd = read.csv(file="BasicInfo_0.csv")
proj_names <- confd$project.name
updated_proj_names <- c()
p_value <- c()
delta <- c()
for (proj_name in proj_names){
	filename <- paste("RQ2_instantiations/",proj_name,".csv",sep="",collapse="")
	cdata = read.csv(file=filename)
	print(proj_name)
	if(length(na.omit(cdata$func_temp_instantiations))==0){
		cdata[1,1] = 0
	}
	if(length(na.omit(cdata$c_style_generics_instantiations))==0){
		cdata[1,2] = 0
	}
	
	# 相关性分析（function templates vs. C-style generics）
	result = wilcox.test(na.omit(cdata$func_temp_instantiations), na.omit(cdata$c_style_generics_instantiations))
	print(result)
	p_value <- c(p_value,result$p.value)
	delta_result = cliff.delta(na.omit(cdata$func_temp_instantiations), na.omit(cdata$c_style_generics_instantiations))
	delta <- c(delta,delta_result$estimate)
	print(delta_result)
}
# BH-adjust for p-values
pvalues_estb <- p_value[1:25]
pvalues_BH_estb <- p.adjust(pvalues_estb, method = "BH", n = length(pvalues_estb))
pvalues_rcnt <- p_value[26:50]
pvalues_BH_rcnt <- p.adjust(pvalues_rcnt, method = "BH", n = length(pvalues_rcnt))
pvalues_BH <- c(pvalues_BH_estb,pvalues_BH_rcnt)
output_data <- data.frame(proj_names,pvalues_BH,delta)
write.csv(output_data, file = "RQ2_instantiations.csv")
