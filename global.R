library(shiny)
library(shinydashboard)
library(ggplot2)
library(tidyverse)
library(yaml)

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