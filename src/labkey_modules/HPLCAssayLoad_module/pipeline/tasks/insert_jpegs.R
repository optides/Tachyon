###
### This Labkey Pipeline script will do 3 things upon uploading of new
### HPLC run images into the HPLC Assay table:
###	1) Make sure there is only 1 HTPlateID listed in all of the incoming files (check first 6 characters of filenames)
###	2) From the filenames, parse out the HTProductionID, Classification, and FileLocation
###	3) Make sure all files exist and are where we expect them to be
###	4) Save the HTProductionID, Classification, Image, and HTPlateID to the HPLC Assay table
###


options(stringsAsFactors = FALSE)
library(Rlabkey)
library(stringr)

source("${srcDirectory}/xlsxToR.R")
source("${srcDirectory}/Utils.R")

jobInfoFile <- sub("..", "../", "${pipeline, taskInfo}", perl=TRUE)
jobInfo <- read.table(jobInfoFile,
                      col.names=c("name", "value", "type"),
                      header=FALSE, check.names=FALSE,
                      stringsAsFactors=FALSE, sep="\t", quote="",
                      fill=TRUE, na.strings="")

inputFiles <- jobInfo$value[ grep(".jpg", jobInfo$name)]

##
##Parameters for this script (login script: _netrc)
##
BASE_URL <- jobInfo$value[ grep("baseUrl", jobInfo$name)]
CONTEXT_PATH <- jobInfo$value[ grep("contextPath", jobInfo$name)]
CONTAINER_PATH <- jobInfo$value[ grep("containerPath", jobInfo$name)]
ASSAY_NAME <- "HPLC Assays"


##########
###### Get the correct paths we are working with:
##########
curDir <- getwd()
upDirs <- str_count(inputFiles[1], "..\\\\")
upDirs <- max(upDirs, str_count(inputFiles[1], "../"))
path_vector <- unlist(strsplit(curDir,.Platform$file.sep))[1:(length(unlist(strsplit(curDir,.Platform$file.sep)))-upDirs)]
image_path <- paste(path_vector, collapse=.Platform$file.sep)
imageFiles <- sub("..\\\\..\\\\..\\\\", "", inputFiles)
imageFiles <- sub("../../../", "", imageFiles)

#################################################################################
## 1) Make sure there is only one HT run specified in the incoming filenames
#################################################################################
HTPlateID <- unique(substr(imageFiles,1,6))
if(length(HTPlateID) > 1){
	cat("ERROR: Only one HTPlateID permitted to be inserted at a time.  Your selection contains multiple HTPlateIDs: \n")
	cat(HTPlateID, "\n")
	stop("Please modify your selection to include only one HTPlateID and try again.")
}

###########################################################################################################
## 2) Parse filenames up into new Dataframe for insertion into assay table
###########################################################################################################

parseFilename <- function(filename, path){
	if(length(unlist(strsplit(filename , "[_]"))) != 4){
		stop(paste0("The detected format of the filename ", filename, " is incorrect.  This is what we are looking for: HTProductionID_Classification_MaxAUNR_RT.jpg, where MaxAUNR and RT are double values, with a decimal point.  For example: HT01011A01_Simple_817.61_7.86.jpg"))
	}
	HTProductionID <- unlist(strsplit(filename , "[_]"))[1]
	Classification <- unlist(strsplit(filename , "[_]"))[2]
	MaxPeakNR <- unlist(strsplit(filename , "[_]"))[3]
	RetentionTime <- unlist(strsplit(filename , "[_]"))[4]
	RetentionTime <- gsub(".jpg", "", RetentionTime)
	RetentionTime <- gsub(".JPG", "", RetentionTime)
	#HTPlateID <- substr(HTProductionID, 1, 6)
	Image <- paste0(path, "/", filename)
	df <- data.frame(HTProductionID, Classification, Image, MaxPeakNR, RetentionTime)
	return (df)
}
outputDF <- parseFilename(imageFiles[1], image_path)
for(i in 2:length(imageFiles)){
	outputDF <- rbind(outputDF, parseFilename(imageFiles[i], image_path))
}

#############################################################################################################
## 3) Make sure all the files exists where we expect them to exist (HTProduction/Assays/Images/(HTPlateID)/ )
#############################################################################################################
fail <- FALSE
failures <- c()
for(i in 1:length(outputDF[,3])){
	if(!file.exists(outputDF[i,3])){
		fail <- TRUE
		failures <- c(failures, outputDF[i,3])
	}
}

if(fail){
	cat("The following files are not found in their expected location (HTProduction/Assays/Images/(HTPlateID)/).  Please place them there and try again.\n")
	for(i in 1:length(failures)){
		cat(failures[i], "\n")
	}
	stop("Please upload the files to the proper directory and try again.")
}

###################################################################
## 4) Insert data to Database
###################################################################
bprops <- list("HTPlateID"=HTPlateID)
bpl <- list(name=paste("HPLC_", HTPlateID),properties=bprops)
rpl <- list(name=paste("HPLC_", HTPlateID))
if(!is.na(CONTEXT_PATH)){
	BASE_URL <- paste0(BASE_URL, CONTEXT_PATH)
}


assayInfo<- labkey.saveBatch(
	baseUrl=BASE_URL,
	folderPath=CONTAINER_PATH,
	ASSAY_NAME,
	outputDF,
	batchPropertyList=bpl,
	runPropertyList=rpl
)

if(!exists("assayInfo")){
	stop("There was a problem with the insertion.  Please contact administrator.")
}
