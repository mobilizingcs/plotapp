#' Make plot
#'
#' Function to make plot. Currently just wraps around qplot
#'
#' @param data The dataframe
#' @param ... passed on to qplot
#' @importFrom ggplot2 qplot
#' @export
makeplot <- function(data, ...){
  #qplot is weird. use ggplot() instead
  do.call("qplot", as.list(match.call())[-1])
}
