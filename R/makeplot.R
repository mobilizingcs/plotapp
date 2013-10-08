#' Make plot
#'
#' Function to make plot. Currently just wraps around qplot
#'
#' @param data The dataframe
#' @param ... passed on to qplot
#' @importFrom ggplot2 qplot
#' @export
makeplot <- function(data, x, y, ...){
  
  if(missing(y) && is(eval(substitute(x), data), "numeric")){
    return(do.call("makeplot_dotplot", as.list(match.call())[-1]));
  } 
  
  if(is(eval(substitute(x), data), "factor") && is(eval(substitute(y), data), "factor")){
    return(do.call("makeplot_mosaic", as.list(match.call())[-1]));
  }
  
  #qplot is weird. use ggplot() instead
  do.call("qplot", as.list(match.call())[-1]) 
}
