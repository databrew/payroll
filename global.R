library(shiny)
library(shinydashboard)
library(ggplot2)
library(tidyverse)
library(yaml)
library(gsheet)
# library(Quandl)


# Define how to handle vj, xing
vj_to_kelli <- TRUE
xing_to_ben <- TRUE

# Define function for transforming people
people_transform <- function(x){
  if(nrow(x) > 0){
    if(vj_to_kelli){
      x$name <- ifelse(x$name %in% c('Vinny', 'Vince', 'VJ', 'Vincent'), 'Kelli', x$name)
    }
    if(xing_to_ben){
      x$name <- ifelse(x$name %in% c('Xing'), 'Ben', x$name)
    }
  }

  return(x)
}

# Read in credentials
creds <- yaml.load_file('credentials.yaml')
# Turn into table
creds <- tibble(name = names(creds),
                password = as.character(unlist(creds)))

# Function for checking log-in
check_password <- function(user, password){
  
  ok <- TRUE
  msg <- ''
  if(!user %in% creds$name){
    ok <- FALSE
    msg <- paste0(user, ' does not exist.')
  } else {
    right_pass <- creds %>% filter(name == user) %>% .$password
    if(right_pass != password){
      ok <- FALSE
      msg <- paste0('Incorrect password for ', user)
    }
  }
  return(list(ok, msg))
}

# Read in google data
hours <- gsheet2tbl('https://docs.google.com/spreadsheets/d/1dLjT7ODp9LmyAd4pZ_QNnpeP5LtNvfvk-PyGnA32YO4/edit#gid=335157130')
income <- gsheet2tbl('https://docs.google.com/spreadsheets/d/1dLjT7ODp9LmyAd4pZ_QNnpeP5LtNvfvk-PyGnA32YO4/edit#gid=684913063')
payments <- gsheet2tbl('https://docs.google.com/spreadsheets/d/1dLjT7ODp9LmyAd4pZ_QNnpeP5LtNvfvk-PyGnA32YO4/edit#gid=1319225983')
expenses <- gsheet2tbl('https://docs.google.com/spreadsheets/d/1dLjT7ODp9LmyAd4pZ_QNnpeP5LtNvfvk-PyGnA32YO4/edit#gid=0')

# Date format
hours$date <- as.Date(hours$date, format = '%m/%d/%Y')
expenses$date <- as.Date(expenses$date, format = '%m/%d/%Y')
income$date <- as.Date(income$date, format = '%m/%d/%Y')
payments$date <- as.Date(payments$date, format = '%m/%d/%Y')
# Make all data frames
expenses <- data.frame(expenses)
hours <- data.frame(hours)
income <- data.frame(income)
payments <- data.frame(payments)
# Name transform
expenses <- people_transform(expenses)
hours <- people_transform(hours)
income <- people_transform(income)
payments <- people_transform(payments)

# Filter dates function
date_restrict <- function(x, start_date, end_date){
  x %>% filter(date >= start_date, date <= end_date)
}

# Deal with currency conversion

# # Get currency data
# # Commenting out for now, since we now put conversions directly into 
# # the accounting spreadsheets
# currency <- read_csv('https://raw.githubusercontent.com/databrew/payroll/master/currency.csv')
# 
# # Expand out to sys date if needed
# currency <- left_join(tibble(date = seq(min(currency$date),
#                                             Sys.Date(),
#                                             by = 1)),
#                       currency) 
# currency <- currency %>% arrange(date) %>%
#   tidyr::fill(usd_to_cad, usd_to_eur, .direction = 'down')
# 
# # Create usd columns
# expenses <-
#   left_join(expenses, currency,
#             by = 'date') %>%
#   mutate(usd = ifelse(currency == 'CAD',
#                       amount / usd_to_cad,
#                       ifelse(currency == 'EUR',
#                              amount / usd_to_eur,
#                              amount)))
# 
# income <- left_join(income, currency,
#                     by = 'date') %>%
#   mutate(usd = ifelse(currency == 'CAD',
#                       amount / usd_to_cad,
#                       ifelse(currency == 'EUR',
#                              amount / usd_to_eur,
#                              amount)))
# payments <- left_join(payments, currency,
#                         by = 'date') %>%
#   mutate(usd = ifelse(currency == 'CAD',
#                       amount / usd_to_cad,
#                       ifelse(currency == 'EUR',
#                              amount / usd_to_eur,
#                              amount)))

# NA to 0
na_to_zero <- function(x){
  ifelse(is.na(x), 0, round(x, digits = 2))
}
