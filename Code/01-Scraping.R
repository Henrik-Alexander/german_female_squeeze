### 01-Scraping ############################
# Purpose: Downloading the population data #
# Author: Henrik-Alexander Schubert        #
# E-Mail: schubert@demogr.mpg.de           #
# Date: 07.06.2023                         #
# Pre-Requirements: Functions              #
############################################

### Preperations -------------------------------------------------------------

  
  rm(list = ls())
  
  # Load the packages
  source("Functions/Packages.R") # Loads the packages
  source("Functions/Graphics.R") # Loads the graphic style
  source("Functions/Functions.R")# Loads the functions
  source("Functions/Account_information.R") # Load ths account information

  # Years
  start_year <- 1990
  end_year   <- 2021

### Genesis Statistisches Bundesamt ------------------------------------------

  # Part 2: set url
  website <- "https://www-genesis.destatis.de/genesisWS/rest/2020/"
  
  # Part 3: define tasks
  tasks <- c("find/find?", "catalogue/results?", "catalogue/tables?", "catalogue/timeseries/", "data/table?")
  names <- c("find", "results", "tables", "timeseries", "data")
  end <- c("&term=Population&category=all&pagelength=100&language=de", "&selection=*12411*&area=all&pagelength=100&language=de",
           "&selection=12411-0018&area=all%searchcriterion=&pagelength=100&language=de",
            "&selection=12411-0018&area=all&pagelength=20&language=de", 
            "&name=11111-0001&area=all&compress=false&transpose=false&startyear=&endyear=&timeslices=&regionalvariable=&regionalkey=&classifyingvariable1=&classifyingkey1=&classifyingvariable2=&classifyingkey2=&classifyingvariable3=&classifyingkey3=&job=false&stand=01.01.1970&language=de")
  
  # Part 4: set number of data
  data_nr <- "12411-0018"
  
  # combine the different insertations
  request <- cbind(names, tasks, end)  %>% as.data.frame()
  
  # Load the data from genesis
  res <- genesis_api(task = "results", request)
  
  # create a data frame
  res <- res$List %>% bind_rows()
  
  # The search term
  Code <- res[res$Content == "Bevölkerung: Kreise, Stichtag, Geschlecht, Altersgruppen", ]$Code |> 
    str_remove("\\$FullCache-")
  
  
  # Get the code
  Code <- "12411-0007"

### Variable manual ---------------------------------------------------

# Set the path
path <- paste0("https://www-genesis.destatis.de/genesisWS/rest/2020/catalogue/tables?username=",
               IHRE_KENNUNG, "&password=",
               IHR_PASSWORT, "&selection=",
               Code,"&area=all&searchcriterion=&sortcriterion=&pagelength=250&language=en")

# Set the path
path <- paste0("https://www-genesis.destatis.de/genesisWS/rest/2020/data/timeseries?username=",
               IHRE_KENNUNG, "&password=",
               IHR_PASSWORT, "&name=",
               Code, "&area=all&compress=false&transpose=false&contents=&",
               start_year, "=&",
               end_year, "=&timeslices=&regionalvariable=&regionalkey=&regionalkeycode=&classifyingvariable1=&classifyingkey1=&classifyingkeycode1=&classifyingvariable2=&classifyingkey2=&classifyingkeycode2=&classifyingvariable3=&classifyingkey3=&classifyingkeycode3=&job=false&stand=01.01.1970&language=de")
  
# Load the data
resp <- GET(path)



### Load the data series ----------------------------------------------

# Set the API endpoint URL
url <- "https://www-genesis.destatis.de/genesisWS/rest/online?"

# Set the parameters for the API request
parameters <- list(
  "method" = "GetTable",
  "tableId" = "12411",  # Table ID for population data
  "format" = "json",
  "query" = list(
    list(
      "key" = "REG",
      "values" = c("01", "02", "03"),  # Example: Region codes for Berlin, Hamburg, and Bavaria
      "type" = "code"
    ),
    list(
      "key" = "BEVSTD__ALTER__GESCHLECHT",
      "values" = "*",  # Retrieve available age groups and genders dynamically
      "type" = "code"
    ),
    list(
      "key" = "TIME",
      "values" = "*",  # All available years
      "type" = "code"
    )
  )
)

# Send the API request
response <- GET(url, query = parameters)

# Check the status of the response
if (http_type(response) == "application/json") {
  # Parse the JSON response
  data <- fromJSON(content(response, "text", encoding = "UTF-8"), flatten = TRUE)
  
  # Extract the available age groups and genders from the response
  age_groups <- unique(data$Result$data$BEVSTD__ALTER__GESCHLECHT)
  
  # Modify the parameter values for age groups and genders
  parameters$query[[2]]$values <- age_groups
  
  # Send the API request again with updated parameters
  response <- GET(url, query = parameters)
  
  # Check the status of the updated response
  if (http_type(response) == "application/json") {
    # Parse the JSON response
    data <- fromJSON(content(response, "text", encoding = "UTF-8"), flatten = TRUE)
    
    # Extract the data frame from the response
    population_data <- data$Result$data
    
    # Print the first few rows of the data frame
    print(head(population_data))
  } else {
    print("Error: Failed to retrieve data.")
  }
} else {
  print("Error: Failed to retrieve data.")
}

### Look at the data -----------------------------------------------


# Status cod
status_code(resp)

# Content
content(resp)

# Get the body content
content(resp, "parsed")

# Read the content
content(resp, "text")
########    END     #########
  