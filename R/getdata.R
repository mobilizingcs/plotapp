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
  mydata <- oh.survey_response.read(campaign_urn, serverurl=serverurl,token=token, 
    column_list = "urn:ohmage:user:id,urn:ohmage:prompt:response,urn:ohmage:context:timestamp,urn:ohmage:survey:privacy_state", ...);
  if(nrow(mydata) == 0){
    stop("No survey responses found for this campaign/range.")
  }
  names(mydata) <- sub("^prompt.id.", "", names(mydata));
  mydata$date <- as.Date(mydata$context.timestamp);
  mydata$timestamp <- as.POSIXct(mydata$context.timestamp);
  mydata$user <- as.factor(mydata$user.id);
  mydata$privacy <- as.factor(mydata$survey.privacy_state);
  
  #some fixes
  for(i in seq_along(mydata)){
    if(length(mydata[[i]]) && is.numeric(mydata[[i]]) && (length(unique(mydata[[i]])) < 8)){
      mydata[[i]] <- as.factor(mydata[[i]]);
    }
  }
  
  return(mydata);
}
