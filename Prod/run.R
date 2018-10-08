.libPaths("L:\\FinCont\\Indfin\\DS\\Reinsurance Email\\library")
library(shiny)
folder_address = "L:\\FinCont\\Indfin\\DS\\Reinsurance Email"
runApp(folder_address,host = "0.0.0.0",port = 5051 ,launch.browser = TRUE)