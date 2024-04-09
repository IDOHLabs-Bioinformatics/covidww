library(ggplot2)
args <- commandArgs(T)
theme_set(theme_bw())

input = args[1]

results <- read.csv(input, sep=',')
totals <- aggregate(results$Abundance, by=list(results$Lineage), FUN=sum)
totals$ratio <- round(totals$x / sum(totals$x), 2)
totals$Group.1 <- ifelse(totals$x > 0.5, totals$Group.1, 'Other')
totals <- aggregate(totals$ratio, by=list(totals$Group.1), FUN=sum)


ggplot(totals, aes(x='', y=x, fill=Group.1)) +
  geom_bar(stat='identity', width=1) +
  coord_polar('y', start=0) +
  theme_void() +
  geom_text(aes(label=paste0(x, '%')), position=position_stack(vjust=0.5)) +
  scale_fill_discrete(name='Lineage')
title <- paste0('overall_lineage_presence', Sys.Date(), '.png')
ggsave(title, bg='white')
