#' Make plot
#'
#' Function to make plot. Currently just wraps around qplot
#'
#' @param data The dataframe
#' @param subset subset the data. See ?subset
#' @param x x-variable (as string)
#' @param y y-variable (as string)
#' @param fill coloring variable (as string)
#' @param size size variable (as string)
#' @param facet faceting variable (as string)
#' @param ... passed on to qplot
#' @import ggplot2
#' @examples makeplot(iris, x='Sepal.Width')
#' makeplot(iris, x='Sepal.Width', fill='Species')
#' makeplot(iris, x='Sepal.Width', facet='Species')
#' makeplot(iris, x='Sepal.Width', subset='Species == "virginica"')
#' makeplot(iris, x='Sepal.Width', subset='Species == "virginica" & Sepal.Width > 3')
#' makeplot(iris, x='Species')
#' makeplot(iris, x='Species', fill='Species')
#' makeplot(iris, y='Sepal.Width', x='Sepal.Length', fill='Species')
#' makeplot(iris, x='Species', y='Sepal.Length', fill='Species')
#' makeplot(iris, x='Sepal.Length', y='Species')
#' makeplot(CO2, x='Plant', y='Type')
#' makeplot(CO2, x='Treatment', y='Type')
#' makeplot(CO2, x='Treatment', y='Plant', facet='Type', fill='Plant')
#' @export
makeplot <- function(data, subset, x, y, fill, size, facet){
  
  #subset filtering
  if(!missing(subset)){
    r <- eval(parse(text=subset), data, parent.frame())
    if (!is.logical(r)) 
      stop("'subset' must be logical")
    r <- r & !is.na(r)
    data <- data[r, TRUE, drop = FALSE];
  }
  
  #create the basic ggplot object
  aeslist <- list ( x = as.name(x) );  
  
  if(!missing(fill)) {
    aeslist$fill <- as.name(fill);
    aeslist$colour <- as.name(fill);
  }
  
  if(!missing(y)){
    aeslist$y <- as.name(y);
  }
  
  if(!missing(size)) aeslist$size <- as.name(size); 
  myplot <- ggplot(data, structure(aeslist, class="uneval"))
  
  #extract x from data
  xvar <- eval(as.name(x), data);
  
  #decide what plot to make
  if(missing(y)){
    #one dimensional plots
    if(is.numeric(xvar)){
      bins <- max(30, round(length(xvar) ^ 0.75))
      binwidth <- diff(range(xvar)) / bins;
      peak <- max(table(round(xvar/binwidth)))
      aspectratio <- 1.8;
      dotsize <- min(1, bins/peak/aspectratio);
      myplot <- myplot + geom_dotplot(stackgroups = TRUE,  method = "histodot", binwidth=binwidth, dotsize=dotsize) + ylab("") + opts(axis.text.y=theme_blank());
    } else {
      myplot <- myplot + geom_bar();
    }
  } else {
    #two dimensional plots
    yvar <- eval(as.name(y), data);
    #if(is(xvar, "factor") && is(yvar, "factor")){
    #  return(makeplot_mosaic(x=x, y=y, fill=fill, size=size));
    #} else if
    if(is.quant(xvar)){
      if(is.quant(yvar)){
        myplot <- myplot + 
          geom_point() +
          geom_smooth(method="lm", se=FALSE, linetype="dashed", size=1);
      } else {
        myplot <- myplot + geom_point(position=position_jitter(width = 0, height=0.15));
      }
    } else if(is.factor(xvar)){
      if(is.quant(yvar)){
        myplot <- myplot + geom_point(position=position_jitter(width = 0.15, height=0));
      } else {
        myplot <- myplot + geom_point(position=position_jitter(width = 0.15, height=0.15));
        #if(!missing(fill)){
        #  myplot <- myplot + geom_point(size=12);           
        #} else {
        #  myplot <- myplot + geom_point(size=12, color="white");   
        #}
        #myplot <- myplot + geom_text(stat="bin2d", aes(label=..count..));  
      }
    }
    #make a little bigger by default
    if(missing(size)){
      myplot$layers[[1]]$geom_params$size = 3;
    }
  }

  #add facet
  if(!missing(facet)){
    myplot <- myplot + facet_wrap(as.formula(paste("~", facet)))
  }
  
  print(myplot)
  invisible();  
}

#quantitative variables are numeric, date or time.
is.quant <- function(x){
  isTRUE(is.numeric(x) || is(x, "Date") || is(x, "POSIXt"));
}