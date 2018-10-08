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

shinyServer(function(input, output, session) {
  volumes <- c(Home = fs::path_home(), "R Installation" = R.home(), getVolumes()())
  shinyDirChoose(input, "directory", roots = volumes, session = session, restrictions = system.file(package = "base"))
  
  
  
  
  ##############################################################################################
  ##############################################################################################
  ###########################################FIRST PRROCESS CODE BLOCK##########################
  ##############################################################################################
  ##############################################################################################
  onclick("Run", {
    #Code written by Henry Diep and Luis Cervantes
    #Reviewed by Luis Cervantes, David South  
    
    ###This script will take a specified reinsurance claims PDF, analyze the page data to identify 'preliminary
    ###notices' and 'requests for payment' using OCR. It will then extract information such as the reinsurer, 
    ###policy number, and insured name. Finally, it will create directories for each policy that will need to be
    ###prepped with supporting documents.
    
    
    #Directory and pdf file to be prepped
    #base <- "L:/FinCont/Indfin/DS/Reinsurance Email/test"
    base <- as.character(input$directory)
    base<-parseDirPath(volumes, input$directory)
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
    
    
    ###########PROGRESS BAR######################################################################
    
    progress <- Progress$new(session, min=1, max=as.numeric(pdf_info(myFile)[2]))
    on.exit(progress$close())
    
    progress$set(message = 'Calculation in progress',
                 detail = 'This may take a while...')
    ############################################################################################
    
    
    #Loop through each page of the specified PDF
    for(i in 1:as.numeric(pdf_info(myFile)[2])){
      nameHold <- c()
      #Use OCR to convert into readable text
      jpeg <- pdf_convert(myFile, format = 'jpeg', dpi = 300, page = i)
      
      ################################
      progress$set(value = i)
      Sys.sleep(0.5)
      #################################
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
            if(grepl("xl re", a[[1]][j]) == TRUE){
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
            if(grepl("xl re", a[[1]][j]) == TRUE){
              myclaims_comp <- append(myclaims_comp, "xl")
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
      print(length(myclaims))
      print(length(myclaims_comp))
      print("ERROR: Unable to parse all Company Codes.\nPlease contact Henry Diep (x7209) for assistance.")
    }
    
    #Source in the python function to create the new folders
    source_python("L:/FinCont/Indfin/DS/reinsurance Email/pyFunctions.py")
    createRequests(base,myclaims_pol)
    
    print('code check 3')
    
    
  })
  ##############################################################################################
  ##############################################################################################
  ###########################################SECOND PRROCESS CODE BLOCK#########################
  ##############################################################################################
  ##############################################################################################
  onclick("Compile", {
    
    #####################Compile. R####################################################
    #Code written by Henry Diep
    #Reviewed by Luis Cervantes
    
    ##This script will call Python to compile the reinsurance claim PDFs for the necessary 
    ###policy number and reinsurer combinations
    
    #Set working directory of backend
    setwd("L:/FinCont/Indfin/DS/reinsurance Email")
    
    #Directory and pdf file to be prepped
    #base <- "L:/FinCont/Indfin/DS/Reinsurance Email/test"
    base <- as.character(input$directory)
    base<-parseDirPath(volumes, input$directory)
    myFile <- list.files(base, pattern = 'pdf$', full.names = TRUE)
    
    #Check if supporting folders are empty
    listPolicies<-list.files(paste(base,'/Requests/policies',sep=''))
    for(i in listPolicies){
      fileCheck <- 1
      listSupport <- list.files(paste(base,"Requests/append",i,"supporting",sep = "/"), pattern = 'pdf$')
      if(length(listSupport) == 0){
        print(paste("No supporting documents found for policy ",i,".\nPlease place files and rerun.",sep = ""))
        fileCheck <- 0
      }
    }
    
    
    #Source in the Python function to compile the PDFs
    if(fileCheck == 1){
      source_python("L:/FinCont/Indfin/DS/reinsurance Email/pyFunctions.py")
      compileRequests(base,myFile,myclaims,myclaims_pol,myclaims_comp,myclaims_name)  
    }
    print('Compile Done')
    
  })  
  ##############################################################################################
  ##############################################################################################
  ###########################################THIRD PRROCESS CODE BLOCK#########################
  ##############################################################################################
  ##############################################################################################  
  onclick('Email',{
    
    ################################email.R###########################################
    #Load in the necessary packages
    ###install.packages("RDCOMClient", repos = "http://www.omegahat.net/R")
    library(RDCOMClient)
    
    #File Path for policy numbers
    #base <- "L:/FinCont/Indfin/DS/Reinsurance Email/test"
    base <- as.character(input$directory)
    base<-parseDirPath(volumes, input$directory)
    
    print('check1')
    
    #Create the static beginning to the email
    template1 = "Hello,\n\nPlease see the attached reimbursement Request for:\n"
    #Create the static ending to the email
    template2 = "\nThank you,\n\nShane McKim\nReinsurance\n949-420-7068"
    
    #Load in the mapping between reinsurer and their emails
    listEmailData <- as.matrix(read.csv("L:/FinCont/Indfin/DS/reinsurance Email/emails.csv",sep = ","))
    listEmailData[21,1] <- 'NA'
    listCodes <- tolower(listEmailData[,1])
    listEmails <- listEmailData[,2]
    listPolicies<-list.files(paste(base,'/Requests/policies',sep=''))
    print('check2')
    #Loop through each created PDF
    for(i in listPolicies){
      compiledFiles <- dir(paste(base,"Requests/policies",i,sep = "/"), pattern = ".pdf")
      for(j in compiledFiles){
        #Extract two letter company code from the file name
        toComp <- gsub("\\.","",str_extract(j,"..\\."))
        #Extract out the name and policy number to be put into the email
        toClaim <- substr(j,1,nchar(j)-6)
        #Find the email for the identified company code
        for(k in 1:length(listCodes)){
          if (grepl(toComp,listCodes[k])){
            sendTo <- listEmails[k]
          }
        }
        #Create a connection to Outlook
        OutApp <- COMCreate("Outlook.Application")
        #Create a new email and begin prepping
        outMail <- OutApp$CreateItem(0)
        outMail[["To"]] = sendTo
        outMail[["subject"]] = "Pacific Life Claims"
        #Combine pieces of email body
        toBody <- paste(template1,toClaim,template2,sep = "\n")
        outMail[["body"]] = toBody
        #Attach the PDF to be sent
        outMail[["Attachments"]]$Add(paste(base,"Requests/policies",i,j,sep = "/"))
        #Save the email as a draft
        outMail$Save()
      }
    }
    
    print('Emails drrafted')
    
  })   
  
  
  
  
  
  
  ## print to console to see how the value of the shinyFiles 
  ## button changes after clicking and selection
  observe({
    cat("\ninput$directory value:\n\n")
    print(input$directory)
  })
  
  observe({
    cat("\ninput$save value:\n\n")
    print(input$save)
  })
  
  ## print to browser
  
  output$directorypath <- renderPrint({
    parseDirPath(volumes, input$directory)
  })
  
  output$savefile <- renderPrint({
    parseSavePath(volumes, input$save)
  })
  
  output$message <- renderText ({
    
    # execute reactive expression defined above
    runandmessage()
    
  })
  
  
})