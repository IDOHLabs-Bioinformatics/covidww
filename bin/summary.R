#!/usr/local/bin/Rscript

library(ggplot2)
library(gridExtra)
args <- commandArgs(T)

overall_pie <- function(frame) {
  # aggregate totals
  frame <- aggregate(frame$Abundance, by=list(frame$Lineage), FUN=sum)
  frame$ratio <- round(frame$x / sum(frame$x), 4) * 100
  frame$Group.1 <- ifelse(frame$ratio > 10, frame$Group.1, 'Other')
  frame <- aggregate(frame$ratio, by=list(frame$Group.1), FUN=sum)
  
  # generate plot
  ggplot(frame, aes(x='', y=x, fill=Group.1)) +
    geom_bar(stat='identity', width=1) +
    coord_polar('y', start=0) +
    theme_void() +
    geom_text(aes(label=paste0(x, '%')), position=position_stack(vjust=0.5)) +
    scale_fill_discrete(name='Lineage') +
    ggtitle('Overall Demix Result')
}

individual <- function(sample, frame) {
  frame <- subset(frame, frame$Sample == sample)
  frame$ratio <- round(frame$Abundance / sum(frame$Abundance), 4) * 100
  frame$Lineage <- ifelse(frame$ratio > 10, frame$Lineage, 'Other')
  frame <- aggregate(frame$ratio, by=list(frame$Lineage), FUN=sum)
  
  ggplot(frame, aes(x='', y=x, fill=Group.1)) +
    geom_bar(stat='identity', width=1) +
    coord_polar('y', start=0) +
    theme_void() +
    geom_text(aes(label=paste0(x, '%')), position=position_stack(vjust=0.5)) +
    scale_fill_discrete(name='Lineage') +
    ggtitle(sample)
}

# read the info
input <- args[1]
results <- read.csv(input, sep=',')
title <- paste0('demix_summary_', Sys.Date(), '.pdf')

# overall plot
overall <- overall_pie(results)

# order the frame so individual plots are easy to find
results <- results[order(results$Sample),]

# individual plots
samples <- unique(results$Sample)
individual_plots <- lapply(samples, individual, results)

plot_count <- length(individual_plots)
if (plot_count > 6) {
  rows <- 3

  pdf(title, width=8, height=10)
  for (i in seq(1, plot_count, by=6)[-length(seq(0, plot_count, by=6))]) {
    grid.arrange(grobs=individual_plots[i:(i+5)], nrow=rows, ncol=2)
  }

  if (i + 5 != length(individual_plots)) {
    grid.arrange(grobs=individual_plots[(i+6):length(individual_plots)],
                 nrow=round(length(individual_plots[(i+6):length(individual_plots)]) / 2, 0) + 1,
                 ncol=2)
  }

  dev.off()
}else{
  rows <- max(1, round(plot_count / 2, 0))
  pdf(title, width=8, height=10)
  grid.arrange(grobs=individual_plots, nrow=rows, ncol=2)
  dev.off()
}

#plot <- ggarrange(overall, plotlist=individual_plots, ncol=2, nrow=rows)

#
#ggexport(plot, filename=title)
