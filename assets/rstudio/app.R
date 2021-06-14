# Title     : Offer Affinity Prediction Dashboard
# Objective : Demonstrate Offer Affinity Prediction Industry Accelerator for Data Science Use Cases

# Sample Materials, provided under license.
# Licensed Materials - Property of IBM
# © Copyright IBM Corp. 2019, 2020. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

### Install any missing packages ###

# Determine packages to install among requirements
list.of.packages <- c("shinyWidgets", "shinyjs", "ggplot2","dplyr","flexdashboard")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) {  # check if there's anything to install
  
  # set default libpath
  if (Sys.getenv("DSX_PROJECT_DIR")!=""){                           # If we are in WSL,
    target <- paste0(Sys.getenv("DSX_PROJECT_DIR"),"/packages/R")   # default to project packages/R
  } else {                                                          # Otherwise,
    target <- .libPaths()[1]                                        # default to first libPath (default)
  }
  
  # check for other valid libpaths

  
  # Install the packages
  print(paste("Installing ", paste(new.packages, collapse = ", "), "to", target))
  install.packages(new.packages, lib = target)
}
# if the packages that get installed have a different version number to development, install the correct version
if(packageVersion("shinyWidgets")!= "0.4.9")
{
  packageUrl <- "https://cran.r-project.org/src/contrib/Archive/shinyWidgets/shinyWidgets_0.4.9.tar.gz"
  install.packages(packageUrl, repos = NULL, type='source')
  packageVersion("shinyWidgets")
}
if(packageVersion("flexdashboard")!= "0.5.1.1")
{
  packageUrl <- "https://cran.r-project.org/src/contrib/Archive/flexdashboard/flexdashboard_0.5.1.tar.gz"
  install.packages(packageUrl, repos = NULL, type='source')
  packageVersion("flexdashboard")
}
if(packageVersion("dplyr")!= "0.8.5")
{
  packageUrl <- "https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.8.5.tar.gz"
  install.packages(packageUrl, repos = NULL, type='source')
  packageVersion("flexdashboard")
}
if(packageVersion("ggplot2")!= "3.2.1")
{
  packageUrl <- "https://cran.r-project.org/src/contrib/Archive/ggplot2/ggplot2_3.2.1.tar.gz"
  install.packages(packageUrl, repos = NULL, type='source')
  packageVersion("ggplot2")
}
# Load required packages
library(shiny)
library(shinyWidgets)
library(shinyjs)
library(DT)
library(httr)
library(rjson)
library(ggplot2)
library(dplyr)

# Load datasets & Cloud Pak for Data API functions
source("lib/load-data.R")
source("lib/icp4d-api.R")

# Load panels
source("homePanel.R")
source("clientPanel.R")

#if(packageVersion("dplyr")!= "0.8.5") { packageUrl <- "https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.8.5.tar.gz" install.packages(packageUrl, repos = NULL, type='source') packageVersion("dplyr") }
# Serve customer profile images
#addResourcePath('profiles', normalizePath('../../misc/rshiny/profiles'))

if(packageVersion("dplyr")!= "0.8.5") { 
  packageUrl <- "https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.8.5.tar.gz" 
  install.packages(packageUrl, repos = NULL, type='source') 
  packageVersion("dplyr") }

ui <- navbarPage(
  "Offer Affinity Prediction",
  id = "proNav",
  inverse = TRUE,
  responsive = TRUE,
  collapsible = TRUE,
  theme = "css/style.css",
  homePanel(),

  clientPanel()
)

server <- function(input, output, session) {
  
  sessionVars <- reactiveValues(selectedClientId = 1039)
  
  homeServer(input, output, session, sessionVars)
  
  clientServer(input, output, session, sessionVars)
}

# Create Shiny app
shinyApp(ui, server)