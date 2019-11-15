library(shiny)
library(shinydashboard)

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
    sub_expenses <- expenses %>% date_restrict(start_date = input$date_range[1],
                                         end_date = input$date_range[2])
    # Define all people
    left <- tibble(name = sort(unique(c(hours$name, expenses$name))))
    
    # Get summary table of hours
    right <- sub_hours %>%
      group_by(name) %>%
      summarise(hours = sum(hours, na.rm = TRUE)) %>%
      mutate(wages_owed = hours * input$wage)
    
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
                             min = 0, max = 100, value = 30, step = NULL)),
          column(8,
                 DT::dataTableOutput('main_table_dt'))
        )
      )
    }
  })
}

shinyApp(ui, server)