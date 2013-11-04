\name{makeplot}
\alias{makeplot}
\title{Make plot}
\usage{
  makeplot(data, subset, x, y, fill, size, facet)
}
\arguments{
  \item{data}{The dataframe}

  \item{subset}{subset the data. See ?subset}

  \item{x}{x-variable (as string)}

  \item{y}{y-variable (as string)}

  \item{fill}{coloring variable (as string)}

  \item{size}{size variable (as string)}

  \item{facet}{faceting variable (as string)}

  \item{...}{passed on to qplot}
}
\description{
  Function to make plot. Currently just wraps around qplot
}
\examples{
makeplot(iris, x='Sepal.Width')
makeplot(iris, x='Sepal.Width', fill='Species')
makeplot(iris, x='Sepal.Width', facet='Species')
makeplot(iris, x='Sepal.Width', subset='Species == "virginica"')
makeplot(iris, x='Sepal.Width', subset='Species == "virginica" & Sepal.Width > 3')
makeplot(iris, x='Species')
makeplot(iris, x='Species', fill='Species')
makeplot(iris, y='Sepal.Width', x='Sepal.Length', fill='Species')
makeplot(iris, x='Species', y='Sepal.Length', fill='Species')
makeplot(iris, x='Sepal.Length', y='Species')
makeplot(CO2, x='Plant', y='Type')
makeplot(CO2, x='Treatment', y='Type')
makeplot(CO2, x='Treatment', y='Plant', facet='Type', fill='Plant')
}

