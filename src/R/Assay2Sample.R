#This script takes a tsv spreadsheet in as input.  One of the column headers must be HTProductionID.
#Based on this HTProductionID, look up all the associated info in 1) Construct sampleset, and 
#2) molecularProperties assay.


library(Rlabkey)
options(stringsAsFactors = FALSE)

inputFile <- "/Users/mbrusnia/Documents/HTLibrary/1K-Perfect-200mAU.csv"

inputDF <- read.table(inputFile, sep=",", header=TRUE, check.names=FALSE)

HTPROD_COL  <- which(names(inputDF) == "HTProduction ID" || names(inputDF) == "HTProductionID")

#get data from HTProduction (HTProductID to ConstructID mapping)
htProdData <- labkey.selectRows(
	baseUrl="http://optides-prod.fhcrc.org",
	folderPath="/Optides/CompoundsRegistry/Samples",
	schemaName="samples",
	queryName="HTProduction",
	colSelect=c("HTProductID", "ConstructID"),
	colNameOpt="fieldname",
	colFilter=makeFilter(c("HTProductID", "IN", paste(inputDF[,HTPROD_COL], collapse=";")))
)

#make sure we have a 1 to 1 lookup
if(length(inputDF[,HTPROD_COL]) != length(htProdData$HTProductID)){
	stop("Not all of your entered HTProductionID's were found in the HTProduction Table.  Please address this error and try again.")
}

#remove prefixing "Construct." if it is present
htProdData$ConstructID <- gsub("Construct.", "", htProdData$ConstructID)
# Count CNT0001396 and CNT0001465 controls.
CNT0001396 <- dim(inputDF[grep("A01|A07|E01|E07",inputDF$HTProductionID),])[1]
CNT0001465 <- dim(inputDF[grep("D06|D12|H06|H12",inputDF$HTProductionID),])[1]
#get data from Construct 
constructData <- labkey.selectRows(
	baseUrl="http://optides-prod.fhcrc.org",
	folderPath="/Optides/CompoundsRegistry/Samples",
	schemaName="samples",
	queryName="Construct",
	colSelect=c("ID", "ParentID", "AlternateName", "Vector", "AASeq"),
	colNameOpt="fieldname",
	colFilter=makeFilter(c("ID", "IN", paste(htProdData$ConstructID, collapse=";")))
)

#make sure we have a 1 to 1 lookup
if((length(htProdData$HTProductID) - CNT0001396 - CNT0001465 + 2) != length(constructData$ID)){
	stop("Not all of your entered HTProductionID's were mapped to a corresponding construct in the Construct Table.  Please address this error and try again.")
}


#get data from Molecular Properties 
molecularPropertiesData <- labkey.selectRows(
	baseUrl="http://optides-prod.fhcrc.org",
	folderPath="/Optides/InSilicoAssay/MolecularProperties",
	schemaName="assay.general.InSilicoAssay",
	queryName="Data",
	colSelect=c("ID", "AverageMass", "MonoisotopicMass", "pI"),
	colNameOpt="fieldname",
	colFilter=makeFilter(c("ID", "IN", paste(htProdData$ConstructID, collapse=";")))
)

#make sure we have a 1 to 1 lookup
if(length(constructData$ID) != length(molecularPropertiesData$ID)){
	stop("Not all of your entered HTProductionID's were mapped to a corresponding ID in the MolecularProperties Table.  Please address this error and try again.")
}


results <-data.frame()
for(i in 1:length(inputDF[,HTPROD_COL])){
	curRow <- data.frame(inputDF[i,], check.names=FALSE)
	curConstID <- htProdData$ConstructID[htProdData$HTProductID == inputDF[i, HTPROD_COL]][1]

	if(length(curConstID) == 1){
		curRow <-cbind(curRow, constructData[constructData$ID == curConstID,][1,])
		curRow <-cbind(curRow, molecularPropertiesData[molecularPropertiesData$ID == curConstID, c("AverageMass", "MonoisotopicMass", "pI")][1,])
	}else{
		curRow <- cbind(curRow, ID="", ParentID="", AlternateName="", Vector="", AASeq="", AverageMass="", MonoisotopicMass="", pI="")
	}

	results <-rbind(results, curRow)
}

outfile <- gsub("\\.(\\w{3,4})$", "_out.\\1", inputFile)
write.table(results, file=outfile, sep = ",", row.names=FALSE, na = "")
#
# 10/10/2016
# 1K Library analysis
assaydata <- labkey.selectRows(
	baseUrl="https://optides-prod.fhcrc.org",
	folderPath="/Optides/HTProduction/Assays",
	schemaName="assay.General.HPLC Assays",
	queryName="Data",
	colSelect=c("RowId", "HTProductionID", "Classification", "MaxPeakNR", "Run/StudyDescription","Run/Batch/HTPlateID"),
	colNameOpt="fieldname",
	showHidden=TRUE,
	colFilter=makeFilter(c("Type", "EQUALS", "Standard"))
)
# Filter out only 1K Library 
data <- assaydata[grep("1K", assaydata$"Run/StudyDescription"),]
CNT0001396 <- data[grep("A01|A07|E01|E07",data$HTProductionID),]
boxplot(CNT0001396$MaxPeakNR~CNT0001396$"Run/Batch/HTPlateID")
CNT0001396[grep("Simple",CNT0001396$Classification),]
CNT0001465 <- data[grep("D06|D12|H06|H12",data$HTProductionID),]
# Remove following parental cells from Midori email
#HT0101: all 4 wells (D06, D12, H06, H12)
#HT0102&103: D06, D12, H06
#All the rest: D06, D12, H12
CNT0001465 <- CNT0001465[-grep("HT01024H12|HT01034H12|HT01044H12|HT01054H12|HT01064H12|HT01074H12|HT01084H12|HT01094H12|HT01104H12|HT01114H12|HT01124H12|HT01134H12|HT01144H12",CNT0001465$HTProductionID),]
boxplot(CNT0001465$MaxPeakNR~CNT0001465$"Run/Batch/HTPlateID")
CNT0001465[grep("Simple", CNT0001465$Classification),]
CNT0001465[grep("Simple",CNT0001465$Classification),]
HPLC <- data
NovoCyte <- labkey.selectRows(
	baseUrl="https://optides-prod.fhcrc.org",
	folderPath="/Optides/HTProduction/Assays",
	schemaName="assay.General.Novocyte",
	queryName="Data",
	colSelect=c("RowId", "HTProductionID", "PlateID","M3_Percent_Parent", "P1_percent_All", "M3_Median_FITC_H"),
	colNameOpt="fieldname",
	showHidden=TRUE,
	colFilter=makeFilter(c("Type", "EQUALS", "Standard"))
)
NovoCyte <- NovoCyte[-grep("HTP|HT0100", NovoCyte$HTProductionID),]
data <- merge(HPLC, NovoCyte, by="HTProductionID")
library(ggplot2)
ggplot(data, aes(x=M3_Percent_Parent,y=MaxPeakNR)) + geom_point(color="red", size=1) + xlab("M3_Percent_Parent") + ylab("MaxPeakNR")+geom_smooth(method = "lm", se=TRUE, level=0.99)
ggplot(data, aes(x=M3_Median_FITC_H,y=MaxPeakNR)) + geom_point(color="red", size=1) + xlab("M3_Median_FITC_H") + ylab("MaxPeakNR")+geom_smooth(method = "lm", se=TRUE, level=0.99)
ggplot(data, aes(x=P1_percent_All,y=MaxPeakNR)) + geom_point(color="red", size=1) + xlab("P1_percent_All") + ylab("MaxPeakNR")+geom_smooth(method = "lm", se=TRUE, level=0.99)


