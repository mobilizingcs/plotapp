#' Get data 
#' 
#' Wrapper for calling survey_response/read
#' 
#' @param campaign_urn Campaign_urn
#' @param severurl Http(s) address of Ohmage server (including /app)
#' @param token authentication token
#' @param ... passed on to oh.survey_response.read
#' @importFrom Ohmage oh.survey_response.read
#' @export
getdata <- function(campaign_urn, serverurl, token, ...){
  mydata <- oh.survey_response.read(campaign_urn, serverurl=serverurl,token=token, ...);
  if(nrow(mydata) == 0){
    stop("No survey responses found for this campaign/range.")
  }
  names(mydata) <- sub("^prompt.id.", "", names(mydata));
  mydata$Date <- as.Date(mydata$context.timestamp);
  mydata$Time <- as.POSIXct(mydata$context.timestamp);
  return(mydata);
}
