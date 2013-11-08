calcsize <- function(x, bins=30){
  binwidth <- diff(range(x)) / bins;
  peak <- max(table(round(x/binwidth)))
  return(bins/peak/1.8);
}
