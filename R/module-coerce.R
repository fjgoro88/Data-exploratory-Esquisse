
#' Coerce data.frame's columns module
#'
#' @param id Module's id
#' @param data A \code{data.frame}.
#' 
#' @name coerce-module
#'
#' @return a \code{reactiveValues} with two slots: \code{data} original \code{data.frame}
#'  with modified columns, and \code{names} column's names with call to coerce method.
#' @export
#' 
#' @importFrom htmltools tags
#' @importFrom shiny NS fluidRow column selectizeInput uiOutput actionButton icon
#' @importFrom shinyWidgets pickerInput
#'
#' @examples
#' \dontrun{
#' 
#' if (interactive()) {
#'   library(esquisse)
#'   library(shiny)
#'   
#'   foo <- data.frame(
#'     num_as_char = as.character(1:10),
#'     char = sample(letters[1:3], 10, TRUE),
#'     fact = factor(sample(LETTERS[1:3], 10, TRUE)),
#'     date_as_char =  as.character(
#'       Sys.Date() + sample(seq(-10, 10), 10, TRUE)
#'     ),
#'     date_as_num = as.numeric(
#'       Sys.Date() + sample(seq(-10, 10), 10, TRUE)
#'     ),
#'     datetime = Sys.time() + sample(seq(-10, 10) * 1e4, 10, TRUE), 
#'     stringsAsFactors = FALSE
#'   )
#'   
#'   ui <- fluidPage(
#'     tags$h2("Coerce module"),
#'     fluidRow(
#'       column(
#'         width = 4,
#'         coerceUI(id = "exemple", data = foo)
#'       ),
#'       column(
#'         width = 8,
#'         verbatimTextOutput(outputId = "print_result"),
#'         verbatimTextOutput(outputId = "print_names")
#'       )
#'     )
#'   )
#'   
#'   server <- function(input, output, session) {
#'     
#'     result <- callModule(module = coerceServer, id = "exemple", data = foo)
#'     
#'     output$print_result <- renderPrint({
#'       str(result$data)
#'     })
#'     output$print_names <- renderPrint({
#'       result$names
#'     })
#'   }
#'   
#'   shinyApp(ui, server)
#' }
#' 
#' }
coerceUI <- function(id, data) {
  ns <- NS(id)
  fluidRow(
    tags$style(
      ".col-coerce {padding-right: 5px; padding-left: 5px;}"
    ),
    tags$script(
      paste(
        "Shiny.addCustomMessageHandler('toggleClass',",
        "function(data) {",
        "if (data.class == 'success') {",
        "$('#' + data.id).removeClass('btn-primary');",
        "$('#' + data.id).addClass('btn-success');",
        "}",
        "if (data.class == 'primary') {",
        "$('#' + data.id).removeClass('btn-success');",
        "$('#' + data.id).addClass('btn-primary');",
        "}",
        # "$('#' + data.id).toggleClass('btn-primary');",
        # "$('#' + data.id).toggleClass('btn-success');",
        "}",
        ");",
        sep = "\n"
      )
    ),
    column(
      width = 5, class = "col-coerce",
      pickerInput(
        inputId = ns("var"),
        label = "Choose a variable:",
        choices = names(data),
        multiple = FALSE,
        width = "100%",
        choicesOpt = list(
          subtext = unlist(lapply(
            X = data, FUN = function(x) class(x)[1]
          ), use.names = FALSE)
        )
      )
    ),
    column(
      width = 4, class = "col-coerce",
      selectizeInput(
        inputId = ns("coerce_to"),
        label = uiOutput(outputId = ns("coerce_to_label"), inline = TRUE),
        choices = c("character", "factor", "numeric", "Date", "POSIXct"),
        multiple = FALSE,
        width = "100%"
      ),
      tags$div(
        id = ns("placeholder-date")
      )
    ),
    column(
      width = 3, class = "col-coerce",
      tags$div(style = "height: 25px;"),
      actionButton(
        inputId = ns("valid_coerce"),
        label = "Coerce",
        icon = icon("play"),
        width = "100%", 
        class = "btn-primary"
      )
    )
  )
}


#' @param input standard \code{shiny} input.
#' @param output standard \code{shiny} output.
#' @param session standard \code{shiny} session.
#'
#' @export
#' 
#' @rdname coerce-module
#' 
#' @importFrom htmltools tags
#' @importFrom shiny reactiveValues renderUI observe removeUI insertUI
#'  textInput observeEvent showNotification updateActionButton icon
coerceServer <- function(input, output, session, data) {
  
  ns <- session$ns
  jns <- function(id) paste0("#", ns(id))
  
  return_data <- reactiveValues(data = data, names = names(data))
  
  output$coerce_to_label <- renderUI({
    var <- data[[input$var]]
    tags$span(
      "From", tags$code(class(var)[1]), "to:"
    )
  })
  
  observe({
    removeUI(selector = jns("options-date"))
    classvar <- class(data[[input$var]])[1]
    if (input$coerce_to == "Date" & classvar %in% c("character", "factor")) {
      insertUI(
        selector = jns("placeholder-date"),
        ui = tags$div(
          id = ns("options-date"),
          textInput(
            inputId = ns("date_format"),
            label = "Specify format:",
            value = "%Y-%m-%d"
          )
        )
      )
    } else if (input$coerce_to == "Date" & classvar %in% c("numeric", "integer")) {
      insertUI(
        selector = jns("placeholder-date"),
        ui = tags$div(
          id = ns("options-date"),
          textInput(
            inputId = ns("date_origin"),
            label = "Specify origin:",
            value = "1970-01-01"
          )
        )
      )
    } else if (input$coerce_to == "POSIXct" & classvar %in% c("character", "factor")) {
      insertUI(
        selector = jns("placeholder-date"),
        ui = tags$div(
          id = ns("options-date"),
          textInput(
            inputId = ns("posixct_format"),
            label = "Specify format:",
            value = "%Y-%m-%d %H:%M:%S"
          )
        )
      )
    } else if (input$coerce_to == "POSIXct" & classvar %in% c("numeric", "integer")) {
      insertUI(
        selector = jns("placeholder-date"),
        ui = tags$div(
          id = ns("options-date"),
          textInput(
            inputId = ns("posixct_origin"),
            label = "Specify origin:",
            value = "1970-01-01 00:00:00"
          )
        )
      )
    }
  })
  
  observeEvent(input$valid_coerce, {
    var <- return_data$data[[input$var]]
    classvar <- class(var)[1]
    args <- list(x = var)
    argsup <- ""
    if (input$coerce_to %in% "Date") {
      if (classvar %in% c("numeric", "integer")) {
        args$origin <- input$date_origin
        argsup <- sprintf(", origin = \"%s\"", input$date_origin)
      } else {
        args$format <- input$date_format
        argsup <- sprintf(", format = \"%s\"", input$date_format)
      }
    } else if (input$coerce_to %in% "POSIXct") {
      if (classvar %in% c("numeric", "integer")) {
        args$origin <- input$posixct_origin
        argsup <- sprintf(", origin = \"%s\"", input$posixct_origin)
      } else {
        args$format <- input$posixct_format
        argsup <- sprintf(", format = \"%s\"", input$posixct_format)
      }
    } else {
      
    }
    var <- withCallingHandlers(
      expr = tryCatch(
        expr = {
          do.call(what = paste0("as.", input$coerce_to), args = args)
        },
        error = function(e) {
          shiny::showNotification(ui = conditionMessage(e), type = "error", session = session)
        }
      ), 
      warning = function(w) {
        shiny::showNotification(ui = conditionMessage(w), type = "warning", session = session)
      }
    )
    return_data$data[[input$var]] <- var
    return_data$names <- replace(
      x = return_data$names, 
      list = which(return_data$names == input$var),
      values = sprintf("as.%s(%s%s)", input$coerce_to, input$var, argsup)
    )
    updateActionButton(
      session = session, 
      inputId = "valid_coerce",
      label = "Coerced !",
      icon = icon("check")
    )
    session$sendCustomMessage(
      type = "toggleClass",
      message = list(id = ns("valid_coerce"), class = "success")
    )
  })
  
  observeEvent(list(input$var, input$coerce_to), {
    updateActionButton(
      session = session, 
      inputId = "valid_coerce",
      label = "Coerce",
      icon = icon("play")
    )
    session$sendCustomMessage(
      type = "toggleClass",
      message = list(id = ns("valid_coerce"), class = "primary")
    )
  }, ignoreInit = TRUE)
  
  return(return_data)
}




