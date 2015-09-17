# This function calculates a default binwidth that will work better
# for the dotplot with large n than the ggplot2 default.
calculate_smart_binwidth <- function(x, aspect_ratio = 2/3){
  x <- as.numeric(x)
  nbins <- max(30, round(sqrt(length(x)) / aspect_ratio))
  range <- range(x, na.rm = TRUE, finite = TRUE)
  if(diff(range) == 0) return(NULL)
  repeat {
    message("trying nbins: ", nbins)
    binwidth <- diff(range)/nbins;
    highest_bin <- max(ggplot2:::bin(x, binwidth = binwidth)$count);
    if(highest_bin < aspect_ratio * nbins) return(binwidth)
    nbins <- ceiling(nbins * 1.03);
  }
}

is_whole_numbers <- function(x){
  if(is.numeric(x)){
    x <- stats::na.omit(as.vector(x))
    whole_numbers <- all.equal(x, as.integer(x))
    width <- diff(range(x))
    return(whole_numbers && width < 15 && width > 0)    
  } else {
    return(FALSE)
  }
}
