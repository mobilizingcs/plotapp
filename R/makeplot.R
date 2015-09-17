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
makeplot <- function(data, subset, x, y, fill, size, facet, fittype, intercept = 0, slope = 0, fitequation = FALSE){

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

  if(!missing(y) && (y != "dotplot")){
    aeslist$y <- as.name(y);
  }

  if(!missing(size)) aeslist$size <- as.name(size);
  myplot <- ggplot(data, structure(aeslist, class="uneval"))

  #extract x from data
  xvar <- eval(parse(text=x)[[1]], data);

  #make a plot
  if(missing(y)){
    if(is.numeric(xvar)){
      myplot <- myplot + geom_bar(colour="white", binwidth = diff(range(xvar, na.rm = TRUE))/15);
    } else if(identical(x, "time")){
      myplot <- myplot + geom_bar(colour="white", binwidth = 3600);
    } else if(inherits(xvar, "Date")){
      myplot <- myplot + geom_bar(colour="white", binwidth = 1);
    } else {
      myplot <- myplot + geom_bar(colour=NA);
    }
  } else if(y == "dotplot"){
    if(is.quant(xvar)){
      myplot <- myplot + geom_dotplot(stackgroups = TRUE, method = "histodot", binwidth = calculate_smart_binwidth(xvar));
    } else {
      myplot <- myplot + geom_dotplot(stackgroups = TRUE);
    }
    myplot <- myplot + ylab("") + theme(axis.text.y=element_blank());
  } else {
    #two dimensional plots
    yvar <- eval(as.name(y), data);
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
    myplot <- myplot + facet_grid(as.formula(paste(facet,"~.")))
  }

  #add line
  if(!missing(intercept) || !missing(slope)){
    myplot <- myplot + geom_abline(intercept = intercept, slope = slope, color = "red", linetype="dashed");
  }
  
  # Fix label for 'time' variable
  if(identical(x, 'time')){
    myplot <- myplot + scale_x_datetime(
      breaks = scales::date_breaks("2 hours"),
      labels = scales::date_format("%H:%M")
    )
  }

  #print the plot
  print(myplot)

  #collect summary data of x and y
  summarydata <- data.frame(x = eval(parse(text=x)[[1]], data))
  names(summarydata) <- x;
  if(!missing(y) && (y != "dotplot")){
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
      exponential = paste0(y, "~", x),
      log = paste(y, "~log(", x, ")")
    )

    family <- if(fittype == "exponential") {
      gaussian("log")
    } else{
      gaussian("identity")
    }

    #formulas dont coerse dates
    if(is(data[[x]], c("Date", "POSIXt"))){
      data[[x]] <- as.numeric(data[[x]]);
      data[[x]] <- data[[x]] - min(data[[x]]) + 1;
    }
    mymodel <- eval(call("glm", as.formula(myformula), quote(data), family=family))
    summarytext <- c(summarytext, "", capture.output(print(coef(mymodel))))
  }

  writeLines(summarytext, "summary.txt")

  #return summarydata
  invisible(summarydata);
}

#quantitative variables are numeric, date or time.
is.quant <- function(x){
  isTRUE(is.numeric(x) || is(x, "Date") || is(x, "POSIXt"));
}
