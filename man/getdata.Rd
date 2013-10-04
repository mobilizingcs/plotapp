\name{getdata}
\alias{getdata}
\title{Get data}
\usage{
  getdata(campaign_urn, serverurl, token, ...)
}
\arguments{
  \item{campaign_urn}{Campaign_urn}

  \item{severurl}{Http(s) address of Ohmage server
  (including /app)}

  \item{token}{authentication token}

  \item{...}{passed on to oh.survey_response.read}
}
\description{
  Wrapper for calling survey_response/read
}

