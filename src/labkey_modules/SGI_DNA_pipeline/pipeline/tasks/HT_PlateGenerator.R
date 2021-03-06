###
### This is an R script for a labkey pipeline import feature
###
### HT_PlateGenerator.R
###


options(stringsAsFactors = FALSE)
library(Rlabkey)

#script required for reading xlsx files:
source("${srcDirectory}/xlsxToR.R")
source("${srcDirectory}/Utils.R")

jobInfoFile <- sub("..", "../", "${pipeline, taskInfo}", perl=TRUE)
jobInfo <- read.table(jobInfoFile,
                      col.names=c("name", "value", "type"),
                      header=FALSE, check.names=FALSE,
                      stringsAsFactors=FALSE, sep="\t", quote="",
                      fill=TRUE, na.strings="")
					  


pathToInputFile <- "${input.xlsx}"

#Parameters for this script (login script: _netrc)
BASE_URL <- jobInfo$value[ grep("baseUrl", jobInfo$name)]
SAMPLE_SETS_SCHEMA_NAME = "Samples"
HT_PRODUCTION_QUERY_NAME = "HTProduction"
SAMPLE_SETS_FOLDER_PATH = "Optides/CompoundsRegistry/Samples"

## read the input
inputDF <- xlsxToR(pathToInputFile, header=FALSE)

##
## Extract only the plate data and its column headers from the file 
##
mynames <- inputDF[17, 1:11]
inputDF <- inputDF[18:(18 - 1 + 96),1:11]
names(inputDF) <- mynames

colHeaders <- names(inputDF)
if(grepl("Construct.*ID", colHeaders[1]) && grepl("Construct.*Name", colHeaders[2]) && grepl("Plate.*ID", colHeaders[3])
	&& grepl("Well.*Location", colHeaders[4]) && grepl("Concentration.*ng/uL", colHeaders[5])
	&& grepl("Volume.*uL", colHeaders[6]) && grepl("Total.*DNA.*ng", colHeaders[7])
	&& grepl("Vector", colHeaders[8]) && grepl("Resistance", colHeaders[9])
	&& grepl("Flanking.*Restriction.*Site", colHeaders[10]) && grepl("Sequence.*Verification", colHeaders[11])){	
	1==1
}else{
	stop("This file does not conform to the expected format.  Please contact the administrator.")
}

#change SGI headers to FHCRC Optides labkey sampleset headers
names(inputDF)[1:7] <- c("SGIID", "ConstructID", "SGIPlateID", "WellLocation", "Concentration_ngPeruL", "Volume_uL", "TotalDNA_ng") 


#
#now prepare data for insertion into HTProduction
#

#added 10/13/16 to include new column: ParentID.  this is a lookup field which goes direcly to Construct
inputDF <- cbind(inputDF, ParentID = inputDF$ConstructID)

#added 9/8/16 to correct parentID conflicts between Construct and SGI_DNA
inputDF$ConstructID <- paste0("Construct.", inputDF$ConstructID)

##find the latest HTPPlateID (we will begin with that + 1 for our new HTPPlate)
ssHTP <- labkey.selectRows(
	baseUrl=BASE_URL,
	folderPath=SAMPLE_SETS_FOLDER_PATH,
	schemaName=SAMPLE_SETS_SCHEMA_NAME,
	queryName=HT_PRODUCTION_QUERY_NAME,
	colNameOpt="fieldname",
	colSelect=c("HTQuadPlateID")
)

reproductionPlate <- "${reproduction-plate-bool}"
reproductionPlateID <- "${reproduction-plate-id}"

newHTPlateID <- 100
quadOffset = 0
if(reproductionPlateID == "" || reproductionPlate == "false"){ 
	if(length(ssHTP$HTQuadPlateID) > 0){
		newHTPlateID <- max(as.numeric(substr(ssHTP$HTQuadPlateID, 3, 6))) + 1
	}

	if(nchar(newHTPlateID) == 3){
		newHTPlateID = paste0("0", newHTPlateID)
	}
	newHTPlateID <- paste0("HT", newHTPlateID)
}else{
	newHTPlateID = reproductionPlateID
	
	#make sure the quadrant is valid (i.e. mod 4 == 0)
	quadOffset = max(substr(ssHTP[substr(ssHTP$HTQuadPlateID, 0, 6) == newHTPlateID, "HTQuadPlateID"], 7, 7))
	if(is.na(as.numeric(quadOffset))){
		reverseKeyLookup = list(A=10, B=11, C=12, D=13, E=14, F=15, G=16, H=17, I=18, J=19, K=20, L=21, M=22, N=23, O=24, P=25, Q=26, R=27, S=28)
		quadOffset = reverseKeyLookup[[quadOffset]]
	}else{
		quadOffset = as.numeric(quadOffset)
	}
	
	if(quadOffset %% 4 > 0){
		stop(paste0("Something is seriously wrong.  The last quadrant entered for plateID ", newHTPlateID, " is ", quadOffset , ", which is not a multiple of 4.  Please contact the administrator."))
	}
}

htproductsToInsert <- data.frame(cbind(HTProductID = newHTPlateID, HTQuadPlateID = newHTPlateID, ConstructID = inputDF[, "ConstructID"], WellLocation = inputDF[, "WellLocation"], SGIID = inputDF[, "SGIID"], SGIPlateID = inputDF[, "SGIPlateID"], ParentID = inputDF[, "ParentID"]))

#now calculate quadrant and update/complete Specimen value
#since our format only allows for one digit in the Quadrant specification, we need to map double digits to letters:
quadrantMap <- c(1,2,3,4,5,6,7,8,9,"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W")
for(i in 1:length(htproductsToInsert$HTProductID)){
	wid <- htproductsToInsert$WellLocation[i]
	letter <- substr(wid, 1,1)
	num    <- as.numeric(substr(wid, 2,3))

	quadrant <- 0
	if(letter == "A" || letter == "B" || letter == "C" || letter == "D"){
		if(num < 7){
			quadrant = quadrantMap[1 + quadOffset ]
		}else{
			quadrant = quadrantMap[2 + quadOffset]
		}
	}else{
		if(num < 7){
			quadrant = quadrantMap[3 + quadOffset]
		}else{
			quadrant = quadrantMap[4 + quadOffset]
		}
	}
	htproductsToInsert$HTQuadPlateID[i] <- paste0(htproductsToInsert$HTQuadPlateID[i], quadrant)
	htproductsToInsert$HTProductID[i] <- paste0(htproductsToInsert$HTProductID[i], quadrant, htproductsToInsert$WellLocation[i])

	if(htproductsToInsert$ConstructID[i] == "Construct.Blank"){
		#WAS: htproductsToInsert$ConstructID[i] = "${blanks-replacement}", but now, since this col is a ParentID col, we have to:
		htproductsToInsert$ConstructID[i] = paste0("Construct.", "${blanks-replacement}")
		htproductsToInsert$ParentID[i] = "${blanks-replacement}"
	}
	if(htproductsToInsert$WellLocation[i] == "H06"){
		htproductsToInsert$ConstructID[i] = "Construct.CNT0000000"
		htproductsToInsert$ParentID[i] = "CNT0000000"
	}
}

#take a peak at what we're about to insert
#head(htproductsToInsert)
#sort(htproductsToInsert$HTProductID)
3

##insert data into HTP_Specimen sampleset database
ssHTP_insert <- labkey.importRows(
	baseUrl=BASE_URL,
	folderPath=SAMPLE_SETS_FOLDER_PATH,
	schemaName=SAMPLE_SETS_SCHEMA_NAME,
	queryName=HT_PRODUCTION_QUERY_NAME,
	toImport=htproductsToInsert
)

if(!exists("ssHTP_insert")){
	stop("There was a problem with the plate generation.  Please contact the Administrator.")
}else{
	#completed
	cat(ssHTP_insert$rowsAffected, "ROWS HAVE BEEN INSERTED INTO HTProduction.\n")
}

