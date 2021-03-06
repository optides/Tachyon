###
### This is an R script for a labkey pipeline import feature
###
### HT_PlateGenerator.R - based on a HT delivery file, create a new plate
###   					  in the HTProduction sampleSet
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
mynames <- inputDF[1, 1:7]
inputDF <- inputDF[2:(1 + 96),1:7]

## set colnames and rownames
names(inputDF) <- mynames
rownames(inputDF ) <- seq(length=nrow(inputDF )) 

colHeaders <- names(inputDF)
if(!(grepl("Plate", colHeaders[1]) && grepl("Well.*Location", colHeaders[2]) && grepl("Order.*ID", colHeaders[3])
	&& grepl("name", colHeaders[4]) && grepl("Vector", colHeaders[5]) && grepl("Sequence Validation", colHeaders[6])
	&& grepl("DNA.*amount", colHeaders[7]))){
	
	stop("This file does not conform to the expected format.  Please contact the administrator.")
}

inputDF$Vector <- gsub("-GFP", "", inputDF$Vector)
inputDF$Vector[inputDF$Vector == "blank"] = ""

#change HT headers to FHCRC Optides labkey sampleset headers
names(inputDF)[1:7] <- c("VendorPlateID", "WellLocation", "VendorOrderID", "ConstructID", "Vector", "SequenceValidation", "TotalDNA_ng") 

##ensure wellLocations are 3 characters long
well_locations_list <- strsplit(inputDF$WellLocation, "")
for(i in 1:96){
	if(length(well_locations_list[[i]]) == 2){
		inputDF$WellLocation[i] <- paste0(well_locations_list[[i]][1], "0", well_locations_list[[i]][2])
	}

	#fix DNAID
	ht_dna <- labkey.selectRows(
		baseUrl=BASE_URL,
		folderPath=SAMPLE_SETS_FOLDER_PATH,
		schemaName=SAMPLE_SETS_SCHEMA_NAME,
		queryName="HT_DNA",
		colNameOpt="fieldname",
		colSelect=c("DNAID", "ConstructID", "Vector"),
		colFilter=makeFilter(c("ConstructID", "EQUALS", inputDF$ConstructID[i]), c("Vector", "EQUALS", inputDF$Vector[i]))
	)
	if(length(ht_dna$DNAID) == 1){
		inputDF$DNAID[i] = ht_dna$DNAID[1]
	}
}

#remove units if ng.  if ug, multiply by 1000
inputDF$TotalDNA_ng <- gsub("ng", "", inputDF$TotalDNA_ng)
inputDF$TotalDNA_ng <- gsub("empty", "", inputDF$TotalDNA_ng)

ug_matches <- grep("ug", inputDF$TotalDNA_ng)
if(length(ug_matches) > 0){
	for(i in 1:length(ug_matches)){
		inputDF$TotalDNA_ng[ug_matches[i]] <- gsub("ug", "", inputDF$TotalDNA_ng[ug_matches[i]])
		inputDF$TotalDNA_ng[ug_matches[i]] <- as.numeric(inputDF$TotalDNA_ng[ug_matches[i]]) * 1000
	}
}


#
#now prepare data for insertion into HTProduction
#

#added 10/13/16 to include new column: ParentID.  this is a lookup field which goes direcly to Construct
inputDF <- cbind(inputDF, ParentID = inputDF$ConstructID)

#added 9/8/16 to correct parentID conflicts between Construct and SGI_DNA
#removed 8/24 since new HT_DNA table has it's own DNAID primary key that is not ConstructID, thus it will not conflict with any other sampleset
#inputDF$ConstructID <- paste0("Construct.", inputDF$ConstructID)

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

htproductsToInsert <- data.frame(cbind(HTProductID = newHTPlateID, HTQuadPlateID = newHTPlateID, ConstructID = inputDF[, "ConstructID"], WellLocation = inputDF[, "WellLocation"], VendorOrderID = inputDF[, "VendorOrderID"], VendorPlateID = inputDF[, "VendorPlateID"], ParentID = inputDF[, "ConstructID"], DNAID = inputDF[, "DNAID"]))

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

	if(htproductsToInsert$ConstructID[i] == "empty" || htproductsToInsert$ConstructID[i] == "blank"){
		htproductsToInsert$ConstructID[i] = "${blanks-replacement}"
		htproductsToInsert$ParentID[i] = "${blanks-replacement}"
	}
	if(htproductsToInsert$WellLocation[i] == "H06" || htproductsToInsert$WellLocation[i] == "D06"){
		htproductsToInsert$ConstructID[i] = "CNT0000000"
		htproductsToInsert$ParentID[i] = "CNT0000000"
	}
}

#remove any leftover "empty" strings:
htproductsToInsert[htproductsToInsert$ConstructID == "empty", "ConstructID"] = ""
htproductsToInsert[htproductsToInsert$VendorOrderID == "empty", "VendorOrderID"] = ""
htproductsToInsert[htproductsToInsert$ParentID == "empty", "ParentID"] = ""
htproductsToInsert[htproductsToInsert$ConstructID == "blank", "ConstructID"] = ""
htproductsToInsert[htproductsToInsert$VendorOrderID == "blank", "VendorOrderID"] = ""
htproductsToInsert[htproductsToInsert$ParentID == "blank", "ParentID"] = ""
htproductsToInsert[is.na(htproductsToInsert$DNAID), "DNAID"] = ""

#take a peak at what we're about to insert
#head(htproductsToInsert)
#names(htproductsToInsert)
#sort(htproductsToInsert$HTProductID)

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


