# Code written by Henry Diep, David South
# Reviewed by ___

### This script will take a specified reinsurance claims PDF, analyze the page data to identify 'preliminary
### notices' and 'requests for payment' using OCR. It will then extract information such as the reinsurer, 
### policy number, and insured name. Finally, it will create directories for each policy that will need to be
### prepped with supporting documents.


# 10/8/2018 - David - add my package dir to libPaths
.libPaths("C:/Users/dsouth/Desktop/R Packages")

# Directory and pdf file to be prepped
base <- "L:/FinCont/Indfin/DS/Reinsurance Email/test"
# base <- as.character(input$directory)
# base<-parseDirPath(volumes, input$directory)
myFile <- list.files(base, pattern = 'pdf$', full.names = TRUE)

library(reticulate)
library(pdftools)
library(tesseract)
library(tm)
library(imager)
library(png)
library(staplr)
library(stringr)

# Set working directory of backend
setwd("L:/FinCont/Indfin/DS/reinsurance Email")

# Static variables
prelim <- "notice of death"
claim <- "request for payment"

# Create variables for preliminary notice
myprelims <- c()
myprelims_comp <- c()
myprelims_pol <- c()
myprelims_name <- c()

# Create variables for payment requests
myclaims <- c()
myclaims_comp <- c()
myclaims_pol <- c()
myclaims_name <- c()

# Loop through each page of the specified PDF
for(i in 1:as.numeric(pdf_info(myFile)[2])){
    nameHold <- c()
    jpeg <- pdf_convert(myFile, format = 'jpeg', dpi = 300, page = i) # Use OCR to convert into readable text
    text <- tolower(ocr(jpeg))
    if(grepl(prelim, text)){  # Search the text for our indication of a preliminary notice
        myprelims <- append(myprelims, i)  # Save the page numbers that these were found on
        a <- strsplit(text,"\n")  # Split the page into each line in order to extract the necessary information
        for(j in 1:length(a[[1]])){
            if(grepl("to:",a[[1]][j])){
                if(grepl("\\(", a[[1]][j])){
                myprelims_comp <- append(myprelims_comp, gsub(")","",gsub("(","",str_extract(a[[1]][j],"\\(..\\)"),fixed = TRUE),fixed = TRUE))
                }
                if(grepl("hannover", a[[1]][j])){  # special handling for Hannover
                    myprelims_comp <- append(myprelims_comp, "hl")
                }
                if(grepl("xl re", a[[1]][j])){  # special handling for xl re
                    myprelims_comp <- append(myprelims_comp, "xl")
                }
            }
# 10/8/2018 - David - potentially replace this block for the block immediately below
# Need to review to find a better indication of the correct line other than 'cov' and 'dollar'          
#            if((grepl("cov",a[[1]][j])) & (grepl("dollar",a[[1]][j]))){
#                b <- strsplit(a[[1]][j]," ")
#                myprelims_pol <- append(myprelims_pol, b[[1]][4])
          
                # Extract policy number          
                if(grepl("[A-Za-z0-9]{10}", a[[1]][j])){
                  myprelims_pol <- append(myprelims_pol, str_extract(a[[1]][j], "[a-z0-9]{10}"))
                }
            }
            # Extract the insured name
            # Finding 'client id' and pulling the line prior
            # Since joint life policies are possible, we are appending a list of names into the larger list of names
            if (grepl("client id", a[[1]][j])){
                nameHold <- append(nameHold,a[[1]][j-1])
            }
        }
        myprelims_name <- append(myprelims_name,list(nameHold))
    
     # The following block follows the same process as above, but for the payment requests
     if(grepl(claim, text) == TRUE){
         myclaims <- append(myclaims, i)
         a <- strsplit(text,"\n")
         for(j in 1:length(a[[1]])){
             if(grepl("to:",a[[1]][j]) == TRUE){
                 if(grepl("\\(", a[[1]][j]) == TRUE){
                 myclaims_comp <- append(myclaims_comp, gsub(")","",gsub("(","",str_extract(a[[1]][j],"\\(..\\)"),fixed = TRUE),fixed = TRUE))
                 }
                 if(grepl("hannover", a[[1]][j]) == TRUE){
                     myclaims_comp <- append(myclaims_comp, "hl")
                 }
                 if(grepl("xl re", a[[1]][j])){
                     myclaims_comp <<- append(myclaims_comp, "xl")
                 }
             }
             if((grepl("cov",a[[1]][j]) == TRUE) & (grepl("dollar",a[[1]][j]) == TRUE)){
                 b <- strsplit(a[[1]][j]," ")
                 myclaims_pol <- append(myclaims_pol, b[[1]][4])
             }
             
             if (grepl("client id", a[[1]][j]) == TRUE){
                 nameHold <- append(nameHold,a[[1]][j-1])
             }
         }
         myclaims_name <- append(myclaims_name,list(nameHold))
     }
     file.remove(jpeg)
 }
    
if(length(myclaims) != length(myclaims_comp)){
    print("ERROR: Unable to parse all Company Codes.\nPlease contact Henry Diep (x7209) for assistance.")
}

source_python("L:/FinCont/Indfin/DS/reinsurance Email/pyFunctions.py") #Source in the python function to create the new folders
createRequests(base,myclaims_pol)