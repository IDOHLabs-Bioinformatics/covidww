# check if all required packages are present, install if not
if (system.file(package='ggplot2') == '') {
  install.packages('ggplot2', version='3.4.4', repos='http://cran.us.r-project.org')
}
if (system.file(package='scatterpie') == '') {
  install.packages('scatterpie', version='0.2.1', repos='http://cran.us.r-project.org')
}
if (system.file(package='RColorBrewer') == '') {
  install.packages('RColorBrewer', version='1.1.3', repos='http://cran.us.r-project.org')
}
if (system.file(package='tidygeocoder') == '') {
  install.packages('tidygeocoder', version='1.0.5', repos='http://cran.us.r-project.org')
}
if (system.file(package='maps') == '') {
  install.packages('maps', version='3.4.2', repos='http://cran.us.r-project.org')
}

# load the packages
library(ggplot2)
library(scatterpie)
library(RColorBrewer)
library(tidygeocoder)
theme_set(theme_void())
args <- commandArgs(T)

make_map <- function(frame, size) {
  # set largely distinct colors
  n <- length(unique(frame$lineage)) - 1
  qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
  col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
  colors <- sample(col_vector, n)
  colors <- append(colors, "black")

  # pivot to the proper format for scatterpie
  tmp <- as.data.frame.matrix(xtabs(abundance ~ address + lineage, frame))
  tmp$address <- row.names(tmp)
  row.names(tmp) <- NULL
  
  frame <- unique(merge(subset(frame, select=c(address, state)), tmp, by.x='address', by.y='address'))
  
  # get coordinates
  frame <- geocode(frame, address)
  
  # set a radius
  frame$radius <- size

  # collect labels used for plotting
  columns <- colnames(frame)
  columns <- columns[! columns %in% c('address', 'state', 'lat', 'long', 'radius')]

  # get the map of the state
  state <- subset(map_data('state'), map_data('state')$region %in% tolower(unique(frame$state)))

  # plot
  p <- ggplot(state, aes(long, lat)) +
    geom_map(map=state, aes(map_id=region), fill=NA, color="black") +
    coord_quickmap()
  p + geom_scatterpie(aes(x=long, y=lat, group=address, r=radius),
                      data=frame, cols=columns, alpha=.7) +
    scale_fill_manual(values=colors, name='Variants')
}


make_bar <- function(frame) {
  frame$relative <- frame$abundance / frame$city_total

  ggplot(frame, aes(x=address, y=relative, fill=lineage)) +
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
# metadata <- geocode(metadata, address)

# filter down the results
results <- subset(results, results$Abundance >= .05)

# merge the metadata and results
results <- merge(results, subset(metadata, select=c('Sample', 'address', 'State')),
                by.x='Sample', by.y='Sample')

results <- aggregate(results$Abundance, by=list(results$Lineage, results$address, 
                                                results$State), FUN=sum)

# calculate the total value from all samples in a city
totals <- aggregate(results$x, by=list(results$Group.2), FUN=sum)
results <- merge(results, totals, by.x='Group.2', by.y='Group.1')
colnames(results) <- c('address', 'lineage', 'state','abundance', 'city_total')

# set those with a low frequency as other
results$other <- ifelse(results$abundance / results$city_total <= .05, TRUE, FALSE)

if (sum(results$other == TRUE) > 0) {
  others <- subset(results, results$other == TRUE)
  others$lineage <- 'Other'
  others <- aggregate(others$abundance, by=list(others$address, others$state,
                                                others$lineage, others$city_total, 
                                                others$other),
                      FUN=sum)
  colnames(others) <- c('address', 'state', 'lineage', 'city_total', 'other',
                        'abundance')
  results <- subset(results, results$other == FALSE)
  results <- rbind(results, others)
}

title <- paste0('abundance_map_', Sys.Date(), '.png')
ggsave(title, make_map(results, size), bg='white')
title <- paste0('abundance_bar_', Sys.Date(), '.png')
ggsave(title, make_bar(results), bg='white')

title <- paste0('metadata_merged_demix_result_', Sys.Date(), '.csv')
write.csv(results, title)

