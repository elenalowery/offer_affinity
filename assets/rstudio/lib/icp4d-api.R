# Sample Materials, provided under license.
# Licensed Materials - Property of IBM
# © Copyright IBM Corp. 2019, 2020. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

# Inputs
# hostname <- 'myicpdcluster.example.com'
# username <- 'myusername@example.com'
# password <- 'mypassword'


library(httr)
library(rjson)


collectDeployments <- function(hostname, username, password, target_tag=NULL) {
  
  if (isTRUE(startsWith(hostname, "https://"))) {
    base_url <- hostname
  } else {
    base_url <- sprintf('https://%s', hostname)
  }
  
  if (isTRUE(endsWith(base_url, "/"))) {
    base_url <- sub("/$", "", base_url)
  } 
  
  authResponse = content(GET(url=paste(base_url, '/v1/preauth/validateAuth',sep=''),
                             authenticate(username, password),
                             httr::config(ssl_verifyhost = FALSE, ssl_verifypeer = FALSE)))
  
  
  if("accessToken" %in% names(authResponse)) {
    token <- authResponse$accessToken
  } else if("message" %in% names(authResponse)) {
    stop(paste("ERROR:", authResponse$message))
  } else {
    stop(paste("ERROR:", authResponse))
  }
  
  spaces <- content(GET(url=paste(base_url,'/v4/spaces',sep=''),
                        httr::config(ssl_verifyhost = FALSE, ssl_verifypeer = FALSE),
                        add_headers(Authorization = paste('Bearer', token)),
                        encode="json"))$resources
  spaceNames = list()
  for(space in spaces) {
    spaceNames[[space$metadata$guid]] = space$entity$name
  }
  
  
  validDeployments <- list()
  errorMsg <- list("ERROR: No valid deployments found.", " ")
  
  deployments <- content(GET(url=paste(base_url,'/v4/deployments',sep=''),
                             httr::config(ssl_verifyhost = FALSE, ssl_verifypeer = FALSE),
                             add_headers(Authorization = paste('Bearer', token)),
                             encode="json"))$resources
  
  
  for(deployment in deployments) {
    if(length(target_tag) == 0 || (length(deployment$entity$tags) > 0 && deployment$entity$tags[[1]]$value == target_tag )) {
      
      # select a unique index name for the deployment
      index_name = deployment$entity$name
      i = 1
      while(index_name %in% names(validDeployments)) {
        i = i + 1
        index_name = paste0(deployment$entity$name, ' (', i, ')')
      }
      
      # populate deployment info
      space_guid = strsplit(deployment$entity$space$href, '/')[[1]][[4]]
      validDeployments[[index_name]] = list(
        guid = deployment$metadata$guid, 
        space_id = space_guid, 
        space_name = spaceNames[[space_guid]],
        tags = paste(lapply(deployment$entity$tags, function(x) x$value), collapse=', '),
        scoring_url = deployment$entity$status$online_url$url
      )
    }
  }
  
  if(length(validDeployments) == 0) {
    errorMsg <- c(errorMsg, paste0("Make sure you have Developer or Admin access to a Project Release with a deployment tagged with '",target_tag,"'"))
    stop(paste(errorMsg, collapse='\n'))
  }
  return(list(token=token, deployments=validDeployments))
}

scoreModelDeployment <- function(scoring_url, data, token) {
  
  resp <- content(POST(url = scoring_url,
                       httr::config(ssl_verifyhost = FALSE, ssl_verifypeer = FALSE),
                       add_headers(Authorization = paste('Bearer', token)),
                       body = list(input_data = list(data)),
                       encode = "json",
                       timeout(8)))
  
  if(length(resp$predictions) > 0) {
    return(resp)
  } else if(length(resp$stderr) > 0) {
    return(list(error=resp$stderr))
  } else {
    return(list(error=resp))
  }
}
