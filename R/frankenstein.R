#' A Shiny Creature
#'
#' @return An R6 object
#'
#' @section Methods:
#' \describe{
#'   \item{\code{as_fresh}}{run the app as fresh}
#'   \item{\code{dispose}}{remove old saved states}
#'   \item{\code{list_states}}{list all saved states}
#'   \item{\code{options}}{shiny options}
#'   \item{\code{revive}}{revive an old app from last states or specific one}
#'   \item{\code{server}}{server object}
#'   \item{\code{ui}}{ui object}
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom yesno yesno
#' @importFrom attempt stop_if_not
#' @importFrom shiny shinyApp
#' @importFrom glue glue
#' @importFrom crayon yellow green
#' @export
#'

Creature <- R6::R6Class("Creature", 
                        public = list(
                          ui = NULL, 
                          server = NULL, 
                          onStart = NULL, 
                          options = list(),
                          uiPattern = "/", 
                          enableBookmarking = "server",
                          scenario = "shiny_bookmarks",
                          initialize = function(ui = NULL, 
                                                server = NULL, 
                                                options = list()
                                                ){
                            stop_if_not(ui, is.function, 
                                                 "ui should be a function with `request` as argument")
                            self$ui <- ui
                            self$server <- server 
                            self$options <- options
                          }, 
                          
                          as_fresh = function(ui = NULL, 
                                              server = NULL, 
                                              overwrite = TRUE){
                            if (!dir.exists(self$scenario)){
                              dir.create(self$scenario)
                            }
                            if (!is.null(ui)){
                              if (overwrite){
                                self$ui <- ui
                              }
                            } else {
                              ui <- self$ui
                            }
                            
                            if (!is.null(server)){
                              if (overwrite){
                                self$server <- server
                              }
                            } else {
                              server <- self$server
                            }
                            
                            self$options$launch.browser <- function(appUrl){
                              invisible(.Call("rs_shinyviewer", appUrl, getwd(), 3))
                            }
                            
                            shiny:::ShinySession$set(
                              which = "public",
                              name = "chock",
                              value = chock(),
                              overwrite = TRUE)
                            
                            shinyApp(ui, server, 
                                     self$onStart, self$options, 
                                     self$uiPattern, self$enableBookmarking)
                            
                          }, 
                          
                          revive = function(ui = NULL, 
                                            server = NULL, 
                                            overwrite = TRUE,
                                            id = NULL){
                            
                            if (!dir.exists(self$scenario)){
                              dir.create(self$scenario)
                            }
                            
                            if (!is.null(ui)){
                              if (overwrite){
                                self$ui <- ui
                              }
                            } else {
                              ui <- self$ui
                            }
                            
                            if (!is.null(server)){
                              if (overwrite){
                                self$server <- server
                              }
                            } else {
                              server <- self$server
                            }

                            if (!is.null(id)){
                              a <- list.files(self$scenario)
                              stop_if_not(id, ~ .x %in% a, "Id not found")
                              cat( green( glue::glue( "Launching from id : {id}" ) ), "\n")
                              Sys.sleep(1)
                              
                              self$options$launch.browser <- function(appUrl){
                                
                                url <- glue('{appUrl}/?_state_id_={id}')
                                invisible(.Call("rs_shinyviewer", url, getwd(), 3))
                              }
                            } else {
                              last_state <- get_last_state(self$scenario)
                              if (last_state == 0){
                                cat(green("No previous state found"), "\n")
                                Sys.sleep(1)
                                cat(yellow("Launching the App"), "\n")
                              } else {
                                cat( green( glue( "Last id found : {last_state}" ) ), "\n")
                                Sys.sleep(1)
                                cat(yellow("Launching the App"), "\n")
                                
                                self$options$launch.browser <- function(appUrl){
                                  url <- glue('{appUrl}/?_state_id_={last_state}')
                                  invisible(.Call("rs_shinyviewer", url, getwd(), 3))
                                }
                              } 
                            }
                            
                            shiny:::ShinySession$set(
                              which = "public",
                              name = "chock",
                              value = chock(),
                              overwrite = TRUE)
                            
                            shinyApp(ui, server, 
                                     self$onStart, self$options, 
                                     self$uiPattern, self$enableBookmarking)
                            
                          }, 
                          
                          list_states = function(folder =  "shiny_bookmarks"){
                            a <- list.files(folder, full.names = TRUE)
                            if (length(a) == 0){
                              cat(crayon::green("No previous state found"), "\n")
                              Sys.sleep(1)
                              return(0)
                            }  else {
                              last_state <- do.call(rbind, lapply(a, file.info))
                              last_state$name <- basename(a)
                              last_state <- last_state[rev(order(last_state$mtime)), ]
                              row.names(last_state) <- NULL
                              last <- last_state[, c("name", "mtime")]
                              names(last) <- c("id","last_modified_time")
                              return(last)
                            }
                          }, 
                          
                          dispose = function(folder = "shiny_bookmarks", save_last = TRUE){
                            if (yesno("This function will recursively remove all files from ", folder, ". Are you sure?")) {
                              if(save_last){
                                last_state <- get_last_state(folder)
                                a <- list.files(folder, full.names = TRUE)
                                a <- a[!grepl(last_state, a)]
                              } else {
                                a <- list.files(folder, all.files = TRUE, full.names = TRUE)
                              }
                              x <- lapply(a, unlink, recursive = TRUE)
                              invisible(x)
                            }
                          }
                        )
)

