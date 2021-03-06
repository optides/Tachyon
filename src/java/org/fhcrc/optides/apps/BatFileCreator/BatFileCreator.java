package org.fhcrc.optides.apps.BatFileCreator;

public class BatFileCreator {
	public static String fileSeparator = "/";
	public static String optidesSoftwareDir = "C:" + fileSeparator + "Users" + fileSeparator + "Waters" + fileSeparator + "Desktop" + fileSeparator + "OptidesSoftware" + fileSeparator;
	
	public static void main(String[] args) {
		//BatFileCreator --lef.FileType="arw" --FileStartingNumber=3570 
		//--inputdir="C:/user/mbrusniak/input" --SN=.2 --MaxRTForPeak=11 
		//--classification=2 --MaxMAUForPeak=500 --outdir="C:/user/mbrusniak/output"
		// --filenamePrefix="HT_UPLC_Export"

		Integer fileStartingNumber = 0;
		String fileType = "arw";
		String inputDir = "C:\\Users\\Waters\\Desktop\\HT_UPLC_Export";
		String outDir = "C:\\Users\\Waters\\Desktop\\HT_UPLC_Reports";
		Double sn_ratio = 0.15;
		Double minRTForPeak = 0.95;
		Double maxRTForPeak = 3.15;
		Double maxMAUForPeak = 1.0;
		Integer classification = 2;
		String filenamePrefix = "HT_UPLC_Export";
		String sampleInfoFilename = "SAMPLE.XML";

		
		if(args.length < 1){
			System.out.println("This program REQUIRES 1 parameter to run, and up to 8 other OPTIONAL parameters:");
			printUsage(fileStartingNumber, fileType, inputDir, outDir, sn_ratio = 0.2, minRTForPeak, 
					maxRTForPeak, maxMAUForPeak, classification, filenamePrefix, sampleInfoFilename);
			return;
		}
		
		//get input params
		String[] curParam = null;
		for(int i = 0; i < args.length; i++){
			curParam = args[i].split("=");
			if(curParam[0].equals("--lef.FileType"))
				fileType = curParam[1];
			else if(curParam[0].equals("--FileStartingNumber"))
				fileStartingNumber = Integer.parseInt(curParam[1]);
			else if(curParam[0].equals("--inputdir"))
				inputDir = curParam[1];
			else if(curParam[0].equals("--SN"))
				sn_ratio = Double.parseDouble(curParam[1]);
			else if(curParam[0].equals("--MinRTForPeak"))
				minRTForPeak = Double.parseDouble(curParam[1]);
			else if(curParam[0].equals("--MaxRTForPeak"))
				maxRTForPeak = Double.parseDouble(curParam[1]);
			else if(curParam[0].equals("--MaxMAUForPeak"))
				maxMAUForPeak = Double.parseDouble(curParam[1]);		
			else if(curParam[0].equals("--outdir"))
				outDir = curParam[1];	
			else if(curParam[0].equals("--sampleInput"))
				sampleInfoFilename = curParam[1];	
			else if(curParam[0].equals("--filenamePrefix"))
				filenamePrefix = curParam[1];	
			else if(curParam[0].equals("--Classification"))
				classification = Integer.parseInt(curParam[1]);
			else{
				System.out.println("Unrecognized command line parameter: " + curParam[0]);
				printUsage(fileStartingNumber, fileType, inputDir, outDir, sn_ratio = 0.15,
						minRTForPeak, maxRTForPeak, maxMAUForPeak, classification, filenamePrefix, sampleInfoFilename);
				return;
			}
		}
		
		if(fileStartingNumber == 0){
			System.out.println("Required Parameter \"FileStartingNumber\" missing:");
			printUsage(fileStartingNumber, fileType, inputDir, outDir, sn_ratio = 0.15, minRTForPeak,
					maxRTForPeak, maxMAUForPeak, classification, filenamePrefix, sampleInfoFilename);
			return;
		}
		
		/***  FIRST, PRINT DOS2UNIX COMMANDS ***/
		//deal with quotes and ending "/"
		inputDir = inputDir.replace("\"", "");
		outDir = outDir.replace("\"", "");
		fileType = fileType.replace("\"", "");
		if(!inputDir.endsWith(fileSeparator))
			inputDir += fileSeparator;
		if(!outDir.endsWith(fileSeparator))
			outDir += fileSeparator;
		
		int curOffset = 0;
		for(int i = 0; i < (8 * 12 + 8*2) * 2 ;i++){
			System.out.println(optidesSoftwareDir + "dos2unix.exe\" \"" + inputDir + filenamePrefix + (fileStartingNumber + curOffset) + "." + fileType + "\"");

			if(i == 0)
				curOffset += 5;
			else
				curOffset +=4;
		}
		
		/***  NEXT, PRINT RUN COMMANDS MATCHING UP SAMPLES ***/
		int r_nr_offset = (8*12 + 8*2) * 4;
		Integer h2o0 = 0, h2o1 = 0;
		curOffset = 0;
		for(int i = 0; i < (8 * 12 + 8*2);i++){
			if(i % 14 == 0){
				h2o0 = fileStartingNumber + curOffset;
			}else if(i % 14 == 1){
				h2o1 = fileStartingNumber + curOffset;				
			}else{
				System.out.println("java -jar \"" + optidesSoftwareDir + "HPLCPeakClassifier.jar\" ^");
				System.out.println("--BLANK_R=\"" + inputDir + filenamePrefix + ((i % 2 == 0) ? h2o0:h2o1) + "." + fileType + "\" ^");
				System.out.println("--R=\"" + inputDir + filenamePrefix + (fileStartingNumber + curOffset) + "." + fileType + "\" ^");
				System.out.println("--BLANK_NR=\"" + inputDir + filenamePrefix + (((i % 2 == 0) ? h2o0:h2o1) + r_nr_offset + ((i % 2 == 0 && i < 14) ? 1:0)) + "." + fileType + "\" ^");
				System.out.println("--NR=\"" + inputDir + filenamePrefix + (fileStartingNumber + curOffset + r_nr_offset) + "." + fileType + "\" ^");
				System.out.println("--outdir=\"" + outDir + "\" ^");
				System.out.println("--SN=" + sn_ratio + " ^");
				System.out.println("--Classification=" + classification + " ^");
				System.out.println("--MaxRTForPeak=" + maxRTForPeak + " ^");
				System.out.println("--MinRTForPeak=" + minRTForPeak + " ^");
				System.out.println("--MaxMAUForPeak=" + maxMAUForPeak + " ^");
				System.out.println("--sampleInfo=\"" + inputDir + sampleInfoFilename + "\"");
				
				System.out.println();
			}
			
			if(i == 0)
				curOffset += 5;
			else
				curOffset += 4;
		}
	}

	private static void printUsage(Integer fileStartingNumber, String fileType, String inputDir, String outDir, Double sn_ratio, Double minRTForPeak, Double maxRTForPeak, Double maxMAUForPeak, Integer classification, String filenamePrefix, String sampleInputFilename) {
		System.out.println("BatFileCreator --lef.FileType=awr --FileStartingNumber=3570 --inputdir=path.to.input.dir --sampleInfo=pathToSampleInfoFile --SN=.2 --MaxRTForPeak=11 --MinRTForPeak=11 --classification=2 --MaxMAUForPeak=500 --outdir=path.to.out.dir --filenamePrefix=XYZ");
		System.out.println();
		System.out.println("Only --FileStartingNumber is REQUIRED.  All other parameters are optional and have default values.  These are the currently set values:");
		System.out.println("--FileStartingNumber:\t"+fileStartingNumber);
		System.out.println("--lef.FileType:\t"+fileType);
		System.out.println("--inputDir:\t"+inputDir);
		System.out.println("--outDir:\t"+outDir);
		System.out.println("--sampleInfo:\t"+sampleInputFilename);
		System.out.println("--SN:\t"+sn_ratio);
		System.out.println("--MinRTForPeak:\t"+minRTForPeak);
		System.out.println("--MaxRTForPeak:\t"+maxRTForPeak);
		System.out.println("--MaxMAUForPeak:\t"+maxMAUForPeak);
		System.out.println("--Classification:\t"+classification);
		System.out.println("--filenamePrefix:\t"+filenamePrefix);
		System.out.println();
		
	}

}