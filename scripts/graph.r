library(ggplot2)
library(scales)

argv <- commandArgs(trailingOnly = TRUE)
if ( length(argv) < 2 ) {
  q()
}

csv_file = argv[1]
output_file = argv[2]

csv <- read.csv(csv_file, stringsAsFactors=F)
csv$date <- as.POSIXct(csv$date)
sum = c()
for ( year in levels(factor(csv$year)) ) {
  sum <- c( sum, cumsum(csv$count[csv$year == year]) )
}
csv <- data.frame(
  csv,
  cumsum=sum
)

graph <- ggplot( csv, aes(date, cumsum, group = year) ) + geom_line()
graph <- graph + aes( color = factor(year) )
graph <- graph + scale_x_datetime( 
  labels = date_format("%m"),
  breaks = date_breaks("month")
)
graph <- graph + guides( color = guide_legend("year") )
ggsave(output_file)
