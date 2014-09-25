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
makeplot <- function(data, subset, x, y, fill, size, facet, fittype, fitequation = FALSE){

  #subset filtering
  if(!missing(subset)){
    r <- eval(parse(text=subset), data, parent.frame())
    if (!is.logical(r))
      stop("'subset' must be logical")
    r <- r & !is.na(r)
    data <- data[r, TRUE, drop = FALSE];
  }

  #create the basic ggplot object
  aeslist <- list ( x = parse(text=x)[[1]] );

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
  xvar <- eval(parse(text=x)[[1]], data);

  #decide what plot to make
  if(missing(y)){
    #one dimensional plots
    if(is.numeric(xvar)){
      bins <- max(30, round(length(xvar) ^ 0.75))
      binwidth <- diff(range(xvar)) / bins;
      peak <- max(table(round(xvar/binwidth)))
      aspectratio <- 1.8;
      dotsize <- min(1, bins/peak/aspectratio);
      myplot <- myplot + geom_dotplot(stackgroups = TRUE,  method = "histodot", binwidth=binwidth, dotsize=dotsize) + ylab("") + theme(axis.text.y=element_blank());
    } else {
      myplot <- myplot + geom_bar(colour=NA);
    }
  } else {
    #two dimensional plots
    yvar <- eval(as.name(y), data);
    #if(is(xvar, "factor") && is(yvar, "factor")){
    #  return(makeplot_mosaic(x=x, y=y, fill=fill, size=size));
    #} else if
    if(is.quant(xvar)){
      if(is.quant(yvar)){
        myplot <- myplot + geom_point();
        if(!missing(fittype) && length(fittype)){
          myplot <- myplot + fitline(fittype);
        }
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

  #Robert wants the sizes less big/small
  if(!missing(size)){
    myplot <- myplot + scale_size_continuous(range=c(2,5));
  }

  #add facet
  if(!missing(facet)){
    myplot <- myplot + facet_wrap(as.formula(paste("~", facet)))
  }

  #print the plot
  print(myplot)

  #collect summary data of x and y
  summarydata <- data.frame(x = eval(parse(text=x)[[1]], data))
  names(summarydata) <- x;
  if(!missing(y)){
    summarydata[2] <- data[y];
  }

  #print some statistics
  options(width=100);
  summarytext <- capture.output(summary(summarydata));
  
  #coefficients
  if(!missing(fittype) && length(fittype) && fitequation){
    myformula <- switch(fittype, 
      linear = paste0(y, "~", x),
      quadratic = paste0(y, "~", x, " + I(", x, "^2)"),
      cubic = paste0(y, "~", x, " + I(", x, "^2) + I(", x, "^3)"),
      exponential = paste0(y, "~exp(", x, ")"),
      log = paste(y, "~log(", x, ")")
    )
    
    #formulas dont coerse dates
    if(is(data[[x]], "Date")){
      data[[x]] <- as.numeric(data[[x]])
    }
    mymodel <- eval(call("lm", as.formula(myformula), quote(data)))
    summarytext <- c(summarytext, capture.output(print(summary(mymodel))))
  }
  
  writeLines(summarytext, "summary.txt")

  #return summarydata
  invisible(summarydata);
}

#quantitative variables are numeric, date or time.
is.quant <- function(x){
  isTRUE(is.numeric(x) || is(x, "Date") || is(x, "POSIXt"));
}
