################################email.R###########################################
#Load in the necessary packages
###install.packages("RDCOMClient", repos = "http://www.omegahat.net/R")
library(RDCOMClient)

#File Path for policy numbers
base <- "L:/FinCont/Indfin/DS/Reinsurance Email/test"
#base <- as.character(input$directory)
#base<-parseDirPath(volumes, input$directory)


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