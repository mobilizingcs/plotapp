makeplot_dotplot <- function(data, x, ...){
  myplot <- do.call("qplot", c(as.list(match.call())[-1], geom="blank"));
  myplot + geom_dotplot();
}
