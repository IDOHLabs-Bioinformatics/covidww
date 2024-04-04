library(ggplot2)
library(tidyverse)
library(scatterpie)
library(RColorBrewer)
library(tidygeocoder)
theme_set(theme_void())
args <- commandArgs(T)

make_map <- function(frame, size) {
  # set largely distinct colors
  n <- length(unique(frame$Lineage)) - 1
  qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
  col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
  colors <- sample(col_vector, n)
  colors <- append(colors, "black")

  # pivot to the proper format for scatterpie
  tmp <- frame %>% pivot_wider(names_from = Lineage, values_from = x)
  # set a radius
  tmp$radius <- size

  # collect labels used for plotting
  columns <- colnames(tmp)
  columns <- columns[! columns %in% c('City', 'Sample', 'Abundance', 'State',
                                      'lat', 'long', 'other', 'radius', 'address')]

  # replace NA with 0
  tmp[is.na(tmp)] <- 0

  # get the map of the state
  state <- subset(map_data('state'), map_data('state')$region %in% tolower(unique(frame$State)))

  # plot
  p <- ggplot(state, aes(long, lat)) +
    geom_map(map=state, aes(map_id=region), fill=NA, color="black") +
    coord_quickmap()
  p + geom_scatterpie(aes(x=long, y=lat, group=address, r=radius),
                      data=tmp, cols=columns, alpha=.7) +
    scale_fill_manual(values=colors, name='Variants')
}


make_bar <- function(frame) {
  frame$relative <- frame$Abundance / frame$x
  
  ggplot(frame, aes(x=address, y=relative, fill=Lineage)) +
    geom_bar(stat='identity') +
    theme_bw() +
    ylab('Relative Abundance') +
    xlab('Location')
}


# read the files
input <- args[1]
metadata <- args[2]
size <- as.numeric(args[3])
results <- read.csv(input, sep=',')
metadata <- read.csv(metadata, sep=',')

metadata$address <- paste(metadata$State, metadata$City, sep=',')
metadata <- geocode(metadata, address)

# filter down the results
results <- subset(results, results$Abundance >= .1)

# merge the metadata and results
merged <- merge(results, subset(metadata, select=c('Sample', 'City', 'State', 'lat', 'long', 'address')),
                by.x='Sample', by.y='Sample')
# combined <- aggregate(merged$est_counts, by=list(merged$City, merged$target_id), FUN=sum)

# calculate the total value from all samples in a city
totals <- aggregate(merged$Abundance, by=list(merged$City), FUN=sum)
merged <- merge(merged, totals, by.x='City', by.y='Group.1')

# set those with a low frequency as other
merged$other <- ifelse(merged$Abundance / merged$x <= .05, TRUE, FALSE)

if (sum(merged$other == TRUE) > 0) {
  others <- subset(merged, merged$other == TRUE)
  others$Lineage <- 'Other'
  others <- aggregate(others$Abundance, by=list(others$City, others$Sample,
                                                others$Lineage, others$State,
                                                others$Latitude, others$Longitude,
                                                others$x, others$other),
                      FUN=sum)
  colnames(others) <- c('City', 'Sample', 'Lineage', 'State', 'lat', 'long', 'x', 'other', 'Abundance')
  merged <- subset(merged, merged$other == FALSE)
  merged <- rbind(merged, others)
}

title <- paste('abundance_map_', Sys.Date())
ggsave(paste0(title, '.png'), make_map(merged, size), bg='white')
title <- paste('abundance_bar_', Sys.Date())
ggsave(paste0(title, '.png'), make_bar(merged), bg='white')
# clean up column names before writing
colnames(merged) <- c('City', 'Sample', 'Lineage', 'Abundance', 'State', 'Latitude', 'Longitude', 'Address', 'Location_total', 'Other')
write.csv(subset(merged, select=c('Sample', 'Lineage', 'Abundance', 'Location_total', 'Address', 'Other')), 'metadata_merged_demix_result.csv')

