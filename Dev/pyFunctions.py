#Code written by Henry Diep
#Reviewed by ___

###The following functions are used in the Reinsurance Claims process

#Load the necessary libraries
import os
import sys
import pandas as pd
import numpy as np
import glob as gl
import math
import PyPDF2


#This function will create 2 branches of directories that both contain folders for every unique policy number
#The first directory, ./policies, will be used to store the final compiled PDFs
#The second director, ./append, will store supporting documents for the payment requests
def createRequests(baseFolder,listPolicies):
    if not os.path.exists(baseFolder + "/Requests/forApproval"):
        os.makedirs(baseFolder + "/Requests/forApproval")
        for i in set(listPolicies):
            os.makedirs(baseFolder + "/Requests/policies/" + i)
            os.makedirs(baseFolder + "/Requests/append/" + i)
            os.makedirs(baseFolder + "/Requests/append/" + i + "/supporting")

#This function will compile a PDF for each unique policy number and reinsurer combination specified by the extracted information in the 'pages.R' script
#It will combine the identified payment requests and supporting documents
###This function has the most room for improvement, especially in the triple loop format
def compileRequests(baseFolder,myFile,listPages,listPolicies,listCompanies,listNames):
    #Open and read in the reinsurance claims PDF
    pdfFileObj = open(myFile, 'rb') 
    pdfReader = PyPDF2.PdfFileReader(pdfFileObj)
    pdfApprove = PyPDF2.PdfFileWriter()
    for i in set(listPolicies):
        for j in range(0,len(listPolicies)):
            if listPolicies[j] == i:
                pageObj = pdfReader.getPage(listPages[j]-1)
                pageObj.rotateClockwise(90) 
                pdfApprove.addPage(pageObj) 
        toAppendApprove = [f for f in os.listdir(baseFolder + "/Requests/append/" + i) if f.endswith('.pdf')]
        toAppendApproveSupport = os.listdir(baseFolder + "/Requests/append/" + i + "/supporting")
        for j in toAppendApprove:
            toapp = open(baseFolder + "/Requests/append/" + i + "/" + j,'rb')
            toappread = PyPDF2.PdfFileReader(toapp)
            pdfApprove.appendPagesFromReader(toappread)
        for j in toAppendApproveSupport:
            toapp = open(baseFolder + "/Requests/append/" + i + "/supporting/" + j,'rb')
            toappread = PyPDF2.PdfFileReader(toapp)
            pdfApprove.appendPagesFromReader(toappread)
    newFile = open(baseFolder + "/Requests/forApproval/Approval.pdf", 'wb') 
    pdfApprove.write(newFile)
    newFile.close()                                      
    #Loop through every unique policy and reinsurer combination
    for i in set(listPolicies):
        for k in set(listCompanies):
            #Initialize and clear the output PDF
            pdfWriter = PyPDF2.PdfFileWriter()
            #Reset a count indicator. This will be used to determine if combination interation exists for this reinsurance claims PDF
            count = 0
            #Loop through each existing policy
            for j in range(0,len(listPolicies)):
                #Match the current page with the correct iteration of policy number and reinsurer
                if listCompanies[j] == k and listPolicies[j] == i:
                    #Update count indicator to produce PDF
                    count = 1
                    #Add page to output PDF
                    pageObj = pdfReader.getPage(listPages[j]-1)
                    pdfWriter.addPage(pageObj)
                    #Not sure if this is still needed. Testing required.
                    ind = j
            #Statement TRUE if current page matches current iteration of policy and reinsurer combination
            if count == 1:
                #List all supporting documents for the policy
                toappend = [f for f in os.listdir(baseFolder + "/Requests/append/" + i) if f.endswith('.pdf')]
                #Append all the supporting documents to the output PDF
                for j in toappend:
                    toapp = open(baseFolder + "/Requests/append/" + i + "/" + j,'rb')
                    toappread = PyPDF2.PdfFileReader(toapp)
                    pdfWriter.appendPagesFromReader(toappread)
                newFile = open(baseFolder + "/Requests/policies/"+ i + "/" + str(listNames[ind])+ " - " + i +" "+ k + ".pdf", 'wb') 
                pdfWriter.write(newFile)
                newFile.close()

def addDeath(myPDF,pageNumber,deathDate):
    packet = io.BytesIO()
    # create a new PDF with Reportlab
    can = canvas.Canvas(packet, pagesize=letter)
    can.drawString(100, 350, deathDate)
    can.save()
    #move to the beginning of the StringIO buffer
    packet.seek(0)
    new_pdf = PdfFileReader(packet)
    # read your existing PDF
    existing_pdf = PdfFileReader(open(myPDF, "rb"))
    output = PdfFileWriter()
    # add the "watermark" (which is the new pdf) on the existing page
    page = existing_pdf.getPage(pageNumber)
    page.mergePage(new_pdf.getPage(0))
    output.addPage(page)
    # finally, write "output" to a real file
    outputStream = open("destination.pdf", "wb")
    output.write(outputStream)
    outputStream.close()

def createPreliminary(baseFolder,listPolicies):
    if not os.path.exists(baseFolder + "/Preliminary/forApproval"):
        os.makedirs(baseFolder + "/Preliminary/forApproval")
    for i in set(listPolicies):
        os.makedirs(baseFolder + "/Preliminary/policies/" + i)
        os.makedirs(baseFolder + "/Preliminary/append/" + i)
        os.makedirs(baseFolder + "/Preliminary/append/" + i + "/supporting")



def compilePreliminary(baseFolder,myFile,listPages,listPolicies,listCompanies,listNames):
    #Open and read in the reinsurance claims PDF
    pdfFileObj = open(myFile, 'rb') 
    pdfReader = PyPDF2.PdfFileReader(pdfFileObj)
    pdfApprove = PyPDF2.PdfFileWriter()
    for i in set(listPolicies):
        for j in range(0,len(listPolicies)):
            if listPolicies[j] == i:
                pageObj = pdfReader.getPage(listPages[j]-1)
                pageObj.rotateClockwise(90) 
                pdfApprove.addPage(pageObj) 
        toAppendApprove = [f for f in os.listdir(baseFolder + "/Preliminary/append/" + i) if f.endswith('.pdf')]
        toAppendApproveSupport = os.listdir(baseFolder + "/Preliminary/append/" + i + "/supporting")
        for j in toAppendApprove:
            toapp = open(baseFolder + "/Preliminary/append/" + i + "/" + j,'rb')
            toappread = PyPDF2.PdfFileReader(toapp)
            pdfApprove.appendPagesFromReader(toappread)
        for j in toAppendApproveSupport:
            toapp = open(baseFolder + "/Preliminary/append/" + i + "/supporting/" + j,'rb')
            toappread = PyPDF2.PdfFileReader(toapp)
            pdfApprove.appendPagesFromReader(toappread)
    newFile = open(baseFolder + "/Preliminary/forApproval/Approval.pdf", 'wb') 
    pdfApprove.write(newFile)
    newFile.close()                                      
    #Loop through every unique policy and reinsurer combination
    for i in set(listPolicies):
        for k in set(listCompanies):
            #Initialize and clear the output PDF
            pdfWriter = PyPDF2.PdfFileWriter()
            #Reset a count indicator. This will be used to determine if combination interation exists for this reinsurance claims PDF
            count = 0
            #Loop through each existing policy
            for j in range(0,len(listPolicies)):
                #Match the current page with the correct iteration of policy number and reinsurer
                if listCompanies[j] == k and listPolicies[j] == i:
                    #Update count indicator to produce PDF
                    count = 1
                    #Add page to output PDF
                    pageObj = pdfReader.getPage(listPages[j]-1)
                    pdfWriter.addPage(pageObj)
                    #Not sure if this is still needed. Testing required.
                    ind = j
            #Statement TRUE if current page matches current iteration of policy and reinsurer combination
            if count == 1:
                #List all supporting documents for the policy
                toappend = [f for f in os.listdir(baseFolder + "/Preliminary/append/" + i) if f.endswith('.pdf')]
                #Append all the supporting documents to the output PDF
                for j in toappend:
                    toapp = open(baseFolder + "/Preliminary/append/" + i + "/" + j,'rb')
                    toappread = PyPDF2.PdfFileReader(toapp)
                    pdfWriter.appendPagesFromReader(toappread)
                newFile = open(baseFolder + "/Preliminary/policies/"+ i + "/" + str(listNames[ind])+ " - " + i +" "+ k + ".pdf", 'wb') 
                pdfWriter.write(newFile)
                newFile.close()