library(Quandl)
library(gsheet)
library(tidyverse)
library(yaml)
library(readr)
library(beepr)

# Read in credentials
creds <- yaml.load_file('credentials.yaml')
# Turn into table
creds <- tibble(name = names(creds),
                password = as.character(unlist(creds)))

# # Test to see if connceted to internet
# havingIP <- function() {
#   if (.Platform$OS.type == "windows") {
#     ipmessage <- system("ipconfig", intern = TRUE)
#   } else {
#     ipmessage <- system("ifconfig", intern = TRUE)
#   }
#   validIP <- "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)[.]){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
#   any(grep(validIP, ipmessage))
# }
# connected <- havingIP()
# 
# if(connected){
  ok <- FALSE
  # Get currency data
  currency <- Quandl("BOE/XUDLCDD", 
                     api_key=creds$quandl_api)
  eur_currency <- Quandl("ECB/EURUSD",
                         api_key = creds$quandl_api)
  if(!is.null(currency)){
    if(!is.null(eur_currency)){
      if(nrow(currency) > 0){
        if(nrow(eur_currency) > 0){
          ok <- TRUE
        }
      }
    }
  }
  if(ok){
    names(eur_currency) <- c('date', 'eur_to_usd')
    
    eur_currency$usd_to_eur <- 1 / eur_currency$eur_to_usd
    eur_currency$eur_to_usd <- NULL
    names(currency) <- c('date', 'usd_to_cad')
    # Combine
    currency <- left_join(currency, eur_currency)
    currency <- currency %>% filter(!is.na(usd_to_cad),
                                    !is.na(usd_to_eur))
    # Expand out to sys date if needed
    currency <- left_join(tibble(date = seq(min(currency$date),
                                            Sys.Date(),
                                            by = 1)),
                          currency) 
    currency <- currency %>% arrange(date) %>%
      tidyr::fill(usd_to_cad, usd_to_eur, .direction = 'down')
    
    # Write a csv
    write_csv(currency, 'currency.csv')
    
    # Push to git
    system('git add currency.csv')
    system("git commit -m 'currency update'")
    system(paste0("git push https://'",
                  creds$password[creds$name == 'github_user'],
                  "':'",
                  creds$password[creds$name == 'github_pass'], "'@github.com/databrew/payroll.git"))
    beep(1)
  } else {
    beep(2)
  }
# }
