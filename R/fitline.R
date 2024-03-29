fitline <- function(type = c("linear", "quadratic", "cubic", "exponential", "log", "loess"), se = FALSE){
	type <- match.arg(type);
	switch(type,
		"linear" = geom_smooth(method="glm", colour="navy", se = se),
		"quadratic" = geom_smooth(method="glm", colour="navy", formula = y~poly(x,2), se = se),
		"cubic" = geom_smooth(method="glm", colour="navy", formula = y~poly(x,3), se = se),
		"exponential" = geom_smooth(method="glm", colour="navy", formula = y~x, se = se, family = gaussian(link = 'log')),
		"log" = geom_smooth(method="glm", colour="navy", formula = y~log(x), se = se),
		"loess" = geom_smooth(colour="navy", se = se),
		stop("unknown smooth type")
	)
}
