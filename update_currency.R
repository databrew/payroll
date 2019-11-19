library(Quandl)
library(gsheet)
library(tidyverse)
library(yaml)
library(readr)

# Read in credentials
creds <- yaml.load_file('credentials.yaml')
# Turn into table
creds <- tibble(name = names(creds),
                password = as.character(unlist(creds)))

# Get currency data
currency <- Quandl("BOE/XUDLCDD", 
                   api_key=creds$quandl_api)
eur_currency <- Quandl("ECB/EURUSD",
                       api_key = creds$quandl_api)
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
system('git push')