makeplot_mosaic <- function(data, x, y, fill, size, facets, ...){
  xvar <- deparse(substitute(x))
  yvar <- deparse(substitute(y))
  fillvar <- deparse(substitute(fill))
  
  mydata <- data[c(xvar, yvar)];
  mytable <- table(mydata);
  widths <- c(0, cumsum(apply(mytable, 1, sum)));
  heights <- apply(mytable, 1, function(x){c(0, cumsum(x/sum(x)))});
  
  alldata <- data.frame();
  allnames <- data.frame();
  for(i in 1:nrow(mytable)){
    for(j in 1:ncol(mytable)){
      alldata <- rbind(alldata, c(widths[i], widths[i+1], heights[j, i], heights[j+1, i]));
    }
  }
  colnames(alldata) <- c("xmin", "xmax", "ymin", "ymax")
  
  alldata[[xvar]] <- rep(dimnames(mytable)[[1]],rep(ncol(mytable), nrow(mytable)));
  alldata[[yvar]] <- rep(dimnames(mytable)[[2]],nrow(mytable));
  
  myplot <- ggplot(alldata, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax)) + 
    xlab(paste(xvar, "(count)")) + ylab(paste(yvar, "(proportion)"));
  
  if(!missing(fill)){
    myplot <- myplot + geom_rect(color="white", aes_string(fill=fillvar));
  } else {
    myplot <- myplot + geom_rect(color="white");
  }
  
  myplot
}
