fitline <- function(type = c("linear", "quadratic", "cubic", "exponential", "log", "loess"), se = FALSE){
	type <- match.arg(type);
	switch(type,
		"linear" = geom_smooth(method="lm", colour="navy", fill=NA, group=NA, se = se),
		"quadratic" = geom_smooth(method="lm", colour="navy", fill=NA, group=NA, formula = y~poly(x,2), se = se),
		"cubic" = geom_smooth(method="lm", colour="navy", fill=NA, group=NA, formula = y~poly(x,3), se = se),
		"exponential" = geom_smooth(method="lm", colour="navy", fill=NA, group=NA, formula = y~exp(x), se = se),
		"log" = geom_smooth(method="lm", colour="navy", fill=NA, group=NA, formula = y~log(x), se = se),
		"loess" = geom_smooth(colour="navy", fill=NA, group=NA, se = se),
		stop("unknown smooth type")
	)
}
