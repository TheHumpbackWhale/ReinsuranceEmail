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
    listSupport <- list.files(paste(base,"Requests/append","024325500m","supporting",sep = "/"), pattern = 'pdf$')
    if(length(listSupport) == 0){
        print(paste("No supporting documents found for policy "),i,".\nPlease place files and rerun.")
        fileCheck <- 0
    }
}


#Source in the Python function to compile the PDFs
if(fileCheck == 1){
source_python("L:/FinCont/Indfin/DS/reinsurance Email/pyFunctions.py")
compileFiles(base,myFile,myclaims,myclaims_pol,myclaims_comp,myclaims_name)  
}