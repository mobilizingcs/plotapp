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
  if(grepl("^urn:public:", campaign_urn)){
    demoname <- paste0(sub("urn:public:", "", campaign_urn), "demo")
    mydata <- demodata(demoname, ...)
    names(mydata) <- sub("\\.label$", "", names(mydata));
  } else {
    mydata <- oh.survey_response.read(campaign_urn, serverurl=serverurl,token=token, 
      column_list = "urn:ohmage:user:id,urn:ohmage:prompt:response,urn:ohmage:context:timestamp,urn:ohmage:survey:privacy_state", ...);
    if(nrow(mydata) == 0){
      stop("No survey responses found for this campaign/range.")
    }
    names(mydata) <- sub("^prompt\\.id\\.", "", names(mydata));
  }
  mydata$date <- as.Date(mydata$context.timestamp);
  mydata$datetime <- as.POSIXct(mydata$context.timestamp);
  mydata$time <- strptime(format(mydata$datetime, "%H:%M:%S"), format="%H:%M:%S");
  mydata$day <- factor(format(mydata$datetime, "%a"), ordered=TRUE, levels=c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"))
  mydata$user <- if(length(mydata$user.id)) as.factor(mydata$user.id) else "demo";
  mydata$privacy <-if(length(mydata$survey.privacy_state)) as.factor(mydata$survey.privacy_state) else "shared"
  
  #remove redundant columns
  mydata$survey.privacy_state <- NULL;
  mydata$context.timestamp <- NULL;
  
  #return ze data
  invisible(mydata);
}

demodata <- function(dataset = c("snackdemo", "nutritiondemo", "mediademo", "trashdemo"), start_date = "2000-01-01", end_date = "2050-01-01", ...){
  dataset <- match.arg(dataset)
  mydata <- read.csv(system.file(paste0("demodata/", dataset, ".csv"), package = "plotbuilder"), stringsAsFactors = FALSE)
  dates <- as.Date(mydata$context.timestamp)
  subset(mydata, dates > start_date & dates < end_date)
}
