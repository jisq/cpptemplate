##############################################################
# Class templates
cdata = read.csv(file="RQ1_ClassTempAnalysis.csv")
proj_names <- cdata$project.name
pvalues <- c()
rhos <- c()
for(i in 1:nrow(cdata)){
	proj_name <- cdata[i,1]
	all_data <- c()
	for(j in 2:ncol(cdata)){
		all_data <- c(all_data,cdata[i,j])
	}
	valid_data <- all_data[(!is.na(all_data))]
	revision_seq <- c()
	for(j in 1:length(valid_data)){
		revision_seq <- c(revision_seq,j)
	}
	# correlation analysis: template uses and revision number
	result <- cor.test(valid_data,revision_seq,method="spearman")
	print(proj_name)
	print(result$p.value)
	print(result$estimate)
	#proj_names <- c(proj_names,proj_name)
	pvalues <- c(pvalues,result$p.value)
	rhos <- c(rhos,result$estimate)
}
pvalues_estb <- pvalues[1:25]
pvalues_BH_estb <- p.adjust(pvalues_estb, method = "BH", n = length(pvalues_estb))
pvalues_rcnt <- pvalues[26:50]
pvalues_BH_rcnt <- p.adjust(pvalues_rcnt, method = "BH", n = length(pvalues_rcnt))
pvalues_BH <- c(pvalues_BH_estb,pvalues_BH_rcnt)
output_data <- data.frame(proj_names,pvalues_BH,rhos)
write.csv(output_data, file = "RQ1_ClassTemp_AnalysisResult.csv")
##############################################################
# Function templates
cdata = read.csv(file="RQ1_FuncTempAnalysis.csv")
proj_names <- cdata$project.name
pvalues <- c()
rhos <- c()
for(i in 1:nrow(cdata)){
	proj_name <- cdata[i,1]
	all_data <- c()
	for(j in 2:ncol(cdata)){
		all_data <- c(all_data,cdata[i,j])
	}
	valid_data <- all_data[(!is.na(all_data))]
	revision_seq <- c()
	for(j in 1:length(valid_data)){
		revision_seq <- c(revision_seq,j)
	}
	# correlation analysis: template uses and revision number
	result <- cor.test(valid_data,revision_seq,method="spearman")
	print(proj_name)
	print(result$p.value)
	print(result$estimate)
	#proj_names <- c(proj_names,proj_name)
	pvalues <- c(pvalues,result$p.value)
	rhos <- c(rhos,result$estimate)
}
pvalues_estb <- pvalues[1:25]
pvalues_BH_estb <- p.adjust(pvalues_estb, method = "BH", n = length(pvalues_estb))
pvalues_rcnt <- pvalues[26:50]
pvalues_BH_rcnt <- p.adjust(pvalues_rcnt, method = "BH", n = length(pvalues_rcnt))
pvalues_BH <- c(pvalues_BH_estb,pvalues_BH_rcnt)
output_data <- data.frame(proj_names,pvalues_BH,rhos)
write.csv(output_data, file = "RQ1_FuncTemp_AnalysisResult.csv")