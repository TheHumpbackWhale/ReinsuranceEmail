#Code written by Henry Diep
#Reviewed by ___

###This script will take a specified reinsurance claims PDF, analyze the page data to identify 'preliminary
###notices' and 'requests for payment' using OCR. It will then extract information such as the reinsurer, 
###policy number, and insured name. Finally, it will create directories for each policy that will need to be
###prepped with supporting documents.


#Directory and pdf file to be prepped
base <- "L:/FinCont/Indfin/DS/Reinsurance Email/test"
#base <- as.character(input$directory)
#base<-parseDirPath(volumes, input$directory)
myFile <- list.files(base, pattern = 'pdf$', full.names = TRUE)


#Load in necessary libraries
library(reticulate)
library(pdftools)
library(tesseract)
library(tm)
library(imager)
library(png)
library(staplr)
library(stringr)

#Set working directory of backend
setwd("L:/FinCont/Indfin/DS/reinsurance Email")


#Static variables
prelim <- "notice of death"
claim <- "request for payment"


#Create variables for preliminary notice.
###Revisit building process for preliminary notices
myprelims <- c()
myprelims_comp <- c()
myprelims_pol <- c()
myprelims_name <- c()

#Create variables for payment requests
myclaims <- c()
myclaims_comp <- c()
myclaims_pol <- c()
myclaims_name <- c()



#Loop through each page of the specified PDF
for(i in 1:as.numeric(pdf_info(myFile)[2])){
    nameHold <- c()
    #Use OCR to convert into readable text
    jpeg <- pdf_convert(myFile, format = 'jpeg', dpi = 300, page = i)
    text <- tolower(ocr(jpeg))
    #Search the text for our indication of a preliminary notice
    if(grepl(prelim, text) == TRUE){
        #Save the page numbers that these were found on
        myprelims <- append(myprelims, i)
        #Split the page into each line in order to extract the necessary information
        a <- strsplit(text,"\n")
        for(j in 1:length(a[[1]])){
            if(grepl("to:",a[[1]][j]) == TRUE){
                if(grepl("\\(", a[[1]][j]) == TRUE){
                myprelims_comp <- append(myclaims_comp, gsub(")","",gsub("(","",str_extract(a[[1]][j],"\\(..\\)"),fixed = TRUE),fixed = TRUE))
                }
                if(grepl("hannover", a[[1]][j]) == TRUE){
                    myprelims_comp <- append(myprelims_comp, "hl")
                }
                if(grepl("xl re", a[[1]][j])){
                    myprelims_comp <- append(myprelims_comp, "xl")
                }
            }
            #Extract the policy number
            ###Need to review to find a better indication of the correct line other than 'cov' and 'dollar'
            if((grepl("cov",a[[1]][j]) == TRUE) & (grepl("dollar",a[[1]][j]) == TRUE)){
                b <- strsplit(a[[1]][j]," ")
                myprelims_pol <- append(myprelims_pol, b[[1]][4])
            }
            #Extract the insured name
            #Finding 'client id' and pulling the line prior
            #Since joint life policies are possible, we are appending a list of names into the larger list of names
            if (grepl("client id", a[[1]][j]) == TRUE){
                nameHold <- append(nameHold,a[[1]][j-1])
            }
        }
        myprelims_name <- append(myprelims_name,list(nameHold))
    }
    #The following block follows the same process as above, but for the payment requests
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

#Source in the python function to create the new folders
source_python("L:/FinCont/Indfin/DS/reinsurance Email/pyFunctions.py")
createFolders(base,myclaims_pol)