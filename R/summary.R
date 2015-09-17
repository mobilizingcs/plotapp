#' @export
summary.time_of_day <- function(x, ...){
  out <- summary.POSIXct(x)
  class(out) <- class(x)
  format(out, "%H:%M")
}

#' @export
# summary.time_of_day <- function(x, ...){
#   hour <- as.POSIXlt(x)$hour
#   bins <- .bincode(hour, seq(0, 24, by = 4))
#   groups <- structure(bins, class = c("ordered", "factor"),
#     levels = c("00:00 - 04:00", "04:00 - 08:00", "08:00 - 12:00", 
#                "12:00 - 16:00", "16:00 - 20:00", "20:00 - 00:00"))
#   summary(groups)
# }
