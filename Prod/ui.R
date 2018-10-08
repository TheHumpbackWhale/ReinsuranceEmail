
.libPaths("L:\\FinCont\\Indfin\\DS\\Reinsurance Email\\library")
library(shiny)
library(shinyFiles)
library(fs)
library(shinyjs)
library(reticulate)
library(pdftools)
library(tesseract)
library(tm)
library(imager)
library(png)
library(staplr)
library(stringr)
library(RDCOMClient)

shinyUI(
  pageWithSidebar(
    headerPanel(
      "Reinsurance Claims: Request for Payments"
    ),
    sidebarPanel(
      tags$p("The following buttons will complie the Request for Payments and prep the emails to be sent out."),
      tags$hr(),
      shinyDirButton("directory", "Folder select", "Please select a folder"),
      useShinyjs(), 
      actionButton("Run", "Create Folders"),
      tags$p(),
      
      tags$p("The 'Folder Select' button lets the user select the folder where the pdf of interest is located."),
      tags$p("The 'Create Folders' button will scan through the file for the 'Request for Payment' pages. It will then
             extract the name of the reinsurer, the insured, and policy number for those pages. Lastly, it will create
             a directory of folders for each policy found to have a request for payment."),
      tags$hr(),
      tags$p("Before running the next step, please drop the IPD files in the 'append' folder separated by each policy.
             Within each policy folder, drop all PDFs to be sent to the reinsurers. For documents not sent to the reinsurer,
             but required for approval, place them in the 'Supporting' subfolder in each policy folder."),
      useShinyjs(), 
      actionButton("Compile", "Compile"),
      tags$p(),
      tags$p("The 'Compile' button will compile PDFs for each unique policy number and reinsurer combination. The output will
             be stored in the 'Policies' folder separated by policy number. An additional PDF in the 'forApproval' folder will be
             created that will include all files needed for approval sorted by policy number."),
      tags$hr(),
      useShinyjs(), 
      actionButton("Email", "Draft Emails"),
      tags$p(),
      tags$p("The 'Draft Emails' button will draft the emails to be sent out to the reinsurers for the location specified by 'Folder Select'.
             The emails will be placed in the 'Drafts' folder in your Outlook application.
             Please review the content before sending out."),
      tags$hr()
      ),
    
    mainPanel(
      tags$h4("The output of a folder selection"),
      tags$p(HTML("Please Save the files in sub-folder called append located in the following path:")),
      verbatimTextOutput("directorypath"),
      tags$hr()
    )
      ))
