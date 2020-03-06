library(shiny)
library(shinydashboard)
library(shiny)
library(shinydashboard)
library(ggplot2)
library(tidyverse)
library(yaml)
library(gsheet)

source('global.R')

header <- dashboardHeader(title="DataBrew Payroll")
sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem(
      text="Main",
      tabName="main",
      icon=icon("eye")),
    menuItem(
      text = 'About',
      tabName = 'about',
      icon = icon("cog", lib = "glyphicon"))
  )
)

body <- dashboardBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  tabItems(
    tabItem(
      tabName="main",
      uiOutput('ui_main')
    ),
    tabItem(
      tabName = 'about',
      fluidPage(
        fluidRow(
          div(img(src='logo_clear.png', align = "center"), style="text-align: center;"),
          h4('Hosted by ',
             a(href = 'http://databrew.cc',
               target='_blank', 'Databrew'),
             align = 'center'),
          p('Empowering research and analysis through collaborative data science.', align = 'center'),
          div(a(actionButton(inputId = "email", label = "info@databrew.cc", 
                             icon = icon("envelope", lib = "font-awesome")),
                href="mailto:info@databrew.cc",
                align = 'center')), 
          style = 'text-align:center;'
        )
      )
    )
  )
)

# UI
ui <- dashboardPage(header, sidebar, body, skin="blue")

# Server
server <- function(input, output) {
  
  
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
  

  
  # Reactive values
  logged_in <- reactiveVal(value = FALSE)
  modal_text <- reactiveVal(value = '')
  # Log in modal
  showModal(
    modalDialog(
      uiOutput('modal_ui'),
      footer = NULL
    )
  )
  
  # See if log-in worked
  observeEvent(input$submit, {
    cp <- check_password(user = input$user,
                         password = input$password)
    li <- cp[[1]]
    logged_in(li)
  })
  
  # When OK button is pressed, attempt to log-in. If success,
  # remove modal.
  observeEvent(input$submit, {
    # Did login work?
    li <- logged_in()
    message('li is ', li)
    if(li){
      # Update the reactive modal_text
      modal_text(paste0('Logged in as ', input$user))
      removeModal()
    } else {
      # Update the reactive modal_text
      modal_text(paste0('That user/password combination is not correct.'))
    }
  })
  
  output$modal_ui <- renderUI({
    # Capture the modal text.
    mt <- modal_text()
    # See if we're in account creation vs log in mode
  
      fluidPage(
        h3(textInput('user', 'Username',
                     value = 'joe'),
           passwordInput('password', 'Password')),
        fluidRow(
          column(6,
                 actionButton('submit',
                              'Submit'))
        ),
        p(mt)
      )
  })
  
  # Main table
  main_table <- reactive({
    # Restrict dates
    sub_hours <- hours %>% date_restrict(start_date = input$date_range[1],
                                         end_date = input$date_range[2])
    date_range <- input$date_range
    # save(sub_hours, date_range, file = 'temp.RData')
    sub_expenses <- expenses %>% date_restrict(start_date = input$date_range[1],
                                         end_date = input$date_range[2])
    # Define all people
    left <- tibble(name = sort(unique(c(hours$name, expenses$name))))
    
    # Define wage
    wagey <- input$wage
    
    # Get summary table of hours
    right <- sub_hours %>%
      group_by(name) %>%
      summarise(hours = sum(hours, na.rm = TRUE)) %>%
      mutate(wages_owed = hours * wagey)
    
    # Get summary table of expenses
    right2 <- sub_expenses %>%
      group_by(name) %>%
      summarise(reimbursements_owed = sum(usd, na.rm = TRUE))
    
    # Combine all together
    out <- left_join(left, right) %>% left_join(right2)
    out <- out %>%
      mutate(hours = na_to_zero(hours),
             wages_owed = na_to_zero(wages_owed),
             reimbursements_owed = na_to_zero(reimbursements_owed))
    out$total <- out$wages_owed + out$reimbursements_owed
    names(out) <- c('Name', 'Hours worked', 'Wages owed', 'Reimbursements owed', '(Total)')
    out
  })
  
  # Main table dt
  output$main_table_dt <- DT::renderDataTable({
    x = main_table()
    DT::datatable(x)
  })
  
  # Main page
  output$ui_main <- renderUI({
    li <- logged_in()
    if(!li){
      NULL
    } else {
      start_date_default <- as.Date(cut(Sys.Date() - 29, 'month'))
      end_date_default <- (seq(start_date_default,length=2,by="months")-1)[2]
      fluidPage(
        fluidRow(
          column(4,
                 dateRangeInput('date_range',
                                'Period',
                                start = start_date_default,
                                end = end_date_default),
                 sliderInput('wage', 'Hourly wage',
                             min = 0, max = 100, value = 40, step = NULL)),
          column(8,
                 DT::dataTableOutput('main_table_dt'))
        )
      )
    }
  })
}

shinyApp(ui, server)