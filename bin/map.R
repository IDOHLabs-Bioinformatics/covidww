library(ggplot2)
library(tidyverse)
library(scatterpie)
library(RColorBrewer)
theme_set(theme_void())
args <- commandArgs(T)

make_map <- function(frame1, title) {
  # set largely distinct colors
  n <- length(unique(frame1$Lineage)) - 1
  qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
  col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
  colors <- sample(col_vector, n)
  colors <- append(colors, "black")
  
  # pivot to the proper format for scatterpie
  tmp <- frame1 %>% pivot_wider(names_from = Lineage, values_from = x)
  # set a radius
  tmp$radius <- .15
  
  # collect labels used for plotting
  columns <- colnames(tmp)
  columns <- columns[! columns %in% c('City', 'Sample', 'Abundance', 'State',
                                      'Latitude', 'Longitude', 'other', 'radius')]

  # replace NA with 0
  tmp[is.na(tmp)] <- 0
  
  # get the map of the state
  state <- subset(map_data('state'), map_data('state')$region == tolower(tmp$State[1]))
  
  # plot
  p <- ggplot(state, aes(long, lat)) +
    geom_map(map=state, aes(map_id=region), fill=NA, color="black") +
    coord_quickmap()
  p + geom_scatterpie(aes(x=Longitude, y=Latitude, group=City, r=radius),
                      data=tmp, cols=columns, alpha=.7) +
    scale_fill_manual(values=colors, name='Variants') +
    ggtitle(title)
}

# read the files
input <- args[1]
metadata <- args[2]
results <- read.csv(input, sep=',')
metadata <- read.csv(metadata, sep=',')

title <- paste('Wasterwater Deconvolution Analysis', Sys.Date())


# filter down the results
results <- subset(results, results$Abundance >= .1)

# merge the metadata and results
merged <- merge(results, subset(metadata, select=c('Sample', 'City', 'State', 'Latitude', 'Longitude')), 
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
  colnames(others) <- c('City', 'Sample', 'Lineage', 'State', 'Latitude', 'Longitude', 'x', 'other', 'Abundance')
  merged <- subset(merged, merged$other == FALSE)
  merged <- rbind(merged, others)
}

ggsave(paste0(title, '.png'), make_map(merged, title))
