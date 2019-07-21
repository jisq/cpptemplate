####################################
# ¶ÁÈ¡Êý¾Ý
cdata = read.csv(file="RQ5.csv")
p_values_1 <- cdata$p_values_1
p_values_1 <- p_values_1[-9]
p_values_1_estb <- p_values_1[1:25]
p_values_1_rcnt <- p_values_1[26:49]
pvalues1_BH_estb <- p.adjust(p_values_1_estb, method = "BH", n = length(p_values_1_estb))
pvalues1_BH_rcnt <- p.adjust(p_values_1_rcnt, method = "BH", n = length(p_values_1_rcnt))
pvalues1_BH <- c(pvalues1_BH_estb,pvalues1_BH_rcnt)
pvalues1_BH <- c(pvalues1_BH,-1)

p_values_2 <- cdata$p_values_2
p_values_2 <- p_values_2[-44]
p_values_2 <- p_values_2[-14]
p_values_2_estb <- p_values_2[1:24]
p_values_2_rcnt <- p_values_2[25:48]
pvalues2_BH_estb <- p.adjust(p_values_2_estb, method = "BH", n = length(p_values_2_estb))
pvalues2_BH_rcnt <- p.adjust(p_values_2_rcnt, method = "BH", n = length(p_values_2_rcnt))
pvalues2_BH <- c(pvalues2_BH_estb,pvalues2_BH_rcnt)
pvalues2_BH <- c(pvalues2_BH,-1)
pvalues2_BH <- c(pvalues2_BH,-1)

p_values_3 <- cdata$p_values_3
p_values_3_estb <- p_values_3[1:25]
p_values_3_rcnt <- p_values_3[26:50]
pvalues3_BH_estb <- p.adjust(p_values_3_estb, method = "BH", n = length(p_values_3_estb))
pvalues3_BH_rcnt <- p.adjust(p_values_3_rcnt, method = "BH", n = length(p_values_3_rcnt))
pvalues3_BH <- c(pvalues3_BH_estb,pvalues3_BH_rcnt)

p_values_4 <- cdata$p_values_4
p_values_4_estb <- p_values_4[1:25]
p_values_4_rcnt <- p_values_4[26:50]
pvalues4_BH_estb <- p.adjust(p_values_4_estb, method = "BH", n = length(p_values_4_estb))
pvalues4_BH_rcnt <- p.adjust(p_values_4_rcnt, method = "BH", n = length(p_values_4_rcnt))
pvalues4_BH <- c(pvalues4_BH_estb,pvalues4_BH_rcnt)

output_data <- data.frame(pvalues1_BH,pvalues2_BH,pvalues3_BH,pvalues4_BH)
write.csv(output_data, file = "RQ5_BH_adjust.csv")

