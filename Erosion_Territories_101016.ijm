//Analyses the intensity of chromosome territories from division of the nucleus into 5 concentric shells
//Input image can be 24bit RGB or 16bit ome tiff (Micro-Manager)
//The images must have the correct µm/pixel calibration for the macro to work correctly

//Opening and preparation steps
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
Dialog.create("Check Calibration");
Dialog.addMessage("-All images must be calibrated (µm/pixel)\n-If not Cancel and calibrate\n-Determine the channel order before running");
Dialog.show;
//Get list of all files in folder
dir = getDirectory("Select source directory");
dir2 = getDirectory("Select destination directory");
list = getFileList(dir);
for (r=0; r<list.length; r++) {
	path = dir+list[r];
	
	open(path);//open the files
originalimage = getImageID;
imagenametext = getTitle;
//Get the image name string without the .tif extension
delimiter = ".";
withoutextension = split(imagenametext, delimiter);

//Duplicate the original image and work on that copy
run("Duplicate...", "duplicate");
rename("Duplicate");
duplicate = getImageID;
//If input image is 24bit RGB make it composite
type = bitDepth;
if (type==24) {
run("Make Composite");	
duplicate = getImageID;
}
else{}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//If it's the first image opened show the dialog
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
if (r==0) {
//Run dialog on first image opened
Dialog.create("User input");
//User input for channel order
Dialog.addMessage("-RGB images will be in this order RGB\n-Channel Ordering-Type 0 to ignore channel/channel not present:");
Dialog.addNumber("DAPI", 1);
Dialog.addNumber("FITC", 2);
Dialog.addNumber("TxRd", 3);
Dialog.addNumber("Cy5", 4);
//Checkboxes to confirm which channels are in the image stack
//It is assumed all channels are to be analysed
//labels = newArray("DAPI", "FITC", "TxRd", "Cy5");
//defaults = newArray(0, 0, 0, 0);
//Dialog.addMessage("Select which channels the image contains");
//Dialog.addCheckboxGroup(4, 1, labels, defaults);
Dialog.show;
//Channel order output
order = newArray(4);
order[0] = Dialog.getNumber;
order[1] = Dialog.getNumber;
order[2] = Dialog.getNumber;
order[3] = Dialog.getNumber;

}
//2nd image opened or above don't show the dialog
else{}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//Counts the number of channels in the image to be used, if zero entered
//channel is not present or should be ignored
counter = 0;
for (i=0; i<order.length; i++) {
	if (order[i] != 0) {
	counter = counter+1;
	}
else {
counter = counter;
	}
}

//Duplicate the channels selected by the user and store their imageID's in channelId array
resultheadings = newArray(counter);//Part of headings for each results column
channelId = newArray(counter);//Array to store channel ids
names = newArray("DAPI", "FITC", "TxRd", "Cy5");//Part of headings for each results column
x = 0;//starting index for resultheadings array
q = 0;//Starting index for channelId array
for (i=0; i<order.length; i++) {
	if (order[i] != 0) {
	Stack.setChannel(order[i]);//for the dialog inputs that weren't zero duplicate those channels
	run("Duplicate...", " ");
	channelId[q++] = getImageID;//store the image id in an array
	selectImage(duplicate);//make this image active for the next loop interation	
	resultheadings[x++]=names[i];//stores the order of the channel headings to be used in the results table
	}
else {
	i+1;//skip this channel and increment counter
	}
}
//Array.print(resultheadings);
//waitForUser("test");
selectImage(duplicate);
close;
//Array.print(channelId);
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////


//Nucleus processing
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
run("Colors...", "foreground=white background=white selection=yellow");
//DAPI
selectImage(channelId[0]);
run("Grays");
setMinAndMax(0, 120);
//run("Gaussian Blur...", "sigma=4");  //Add this if nucleus has chromatin dense regions and segmentation of boundary fails
run("Threshold...");//Added to allow manual threshold adjustment. Delete to use auto
//Threshold the nucleus then convert to mask to allow binary manipulations (Erosion)
setAutoThreshold("Huang dark");
waitForUser("Adjust threshold if necessary");//Added to allow manual threshold adjustment. Delete to use auto
run("Close");//Added to allow manual threshold adjustment. Delete to use auto
selectImage(channelId[0]);//Added to allow manual threshold adjustment. Delete to use auto
//setBatchMode(true);
run("Create Mask");
//Makes a selection around the nuclear boundary
//run("Create Selection");
//Measure area
run("Set Measurements...", "area add redirect=None decimal=0");
run("Analyze Particles...", "size=7-Infinity include exclude add");
roiManager("select", 0);
run("Set...", "value=255");
run("Make Inverse");
run("Set...", "value=0");
roiManager("select", 0);
setBatchMode(true);
//Extracts and stores total nuclear area
nuclear_area = getResult("Area", 0);
//Print this to the results table
nucArea = nuclear_area;
nucArea = round(nucArea);//nucleus area as whole number
//print(nucArea);
//1/5 of total area
calc = nuclear_area/5;
//Total segs
totalsegs = 4;
//An array with 4 values, Stores each shells area value
seg_area = newArray(totalsegs);
//Stores total area-1/5 of the total
remainder = nuclear_area-calc;
//Build array that stores each shell area
for (i=0; i<totalsegs; i++){
	seg_area[i] = remainder;
	remainder = remainder-calc;
	//print(seg_area[i]);
    //print(totalsegs);
}
run("Clear Results");

//Erode the nuclear area to create 5 selections with equal area
///////////////////////////////////////////////////////////////////
//Each shell could be given a different colour using an array but not currenlty used
//colour = newArray("green", "yellow", "magenta", "cyan");
//Erode the nucleus until until the area becomes equal to 4/5 total area
//loop to obtain 5 shell selections
current_area=nuclear_area;
//Run this loop 5 times as there needs to be 5 shells
for (i=0; i<4; i++){
//for each of the 5 shells work out its required area by eroding
//and comparing to total area	
for (j=0; j<totalsegs; j++) {
//For each shell keep eroding until area equals 4/5s, then the 3/5s etc 
	while (current_area>seg_area[i]) {
	setOption("BlackBackground", false);
    //run("Gray Morphology", "radius=3 type=[free form] operator=erode text1=[ 0 255 255 255 0  255 255 255 255 255  255 255 255 255 255  255 255 255 255 255  0 255 255 255 0 ]");
    run("Erode");
    run("Create Selection");
    run("Measure");
    current_area = getResult("Area", 0);
    run("Clear Results");	
	}
}
//When each shell area determined add it to ROI Manager
roiManager("Add");
}

selectWindow("mask");
run("Close");
selectWindow("Results");
run("Close");
selectImage(channelId[0]);
resetThreshold();
//Generate ring ROI's
//select ROI 0 & 1 XOR, add
shell = newArray(0,1);
for (i=0; i<4; i++) {
roiManager("Select", shell);
roiManager("XOR");
roiManager("add");
roiManager("Deselect");
roiManager("Select", 0);
roiManager("Delete");
}
roiManager("Select", 0);
roiManager("add");
roiManager("Select", 0);
roiManager("Delete");
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
setBatchMode(false);
//Add the results from the ROI's to an array
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
run("Set Measurements...", "area mean min integrated redirect=None decimal=2");
manager = roiManager("Count");//The number of ring ROI's in ROI manager (5)
nMeasures = 6;//number of measurement parameters+imagename
//Array to store the measurement headings for the results table
measurementheadings = newArray("File Name", "Area", "Mean", "Min", "IntDen", "RawIntDen");
//An array to store all results in one linear list, the length is calulated based on the product of the
//number of channels, measurement parameters e.g.mean, min etc and number of ROIs in ROImanager
flatArray = newArray(counter * nMeasures * manager);
//flatArray starting index
l = 0;
for (c=0; c<counter; c++) {//For each channel
	selectImage(channelId[c]);//image selection	
	run("Subtract Background...", "rolling=1000 sliding");//Runs a background subtraction step to minimise contribution of low intensity pixels representing the background fluorescence signal
	for (v=0; v<manager; v++) {//For each ROI
	roiManager("Select", v);//Select the ROI
	run("Measure");	
		//l++ increments the array index to hold a new value
		flatArray[l++] = imagenametext;
		flatArray[l++] = getResult("Area", v);
		flatArray[l++] = getResult("Mean", v);
		flatArray[l++] = getResult("Min", v);
		flatArray[l++] = getResult("IntDen", v);
		flatArray[l++] = getResult("RawIntDen", v);
	}
run("Clear Results");
}
selectWindow("Results");
run("Close");

//Now populate the Results table row by row
for (c=0; c<counter; c++) {
	for (v=0; v<manager; v++) {
		for (m=0; m<nMeasures; m++) {	
			column = resultheadings[c] + "_" + measurementheadings[m];
			value = flatArray[m + v*nMeasures + c*manager*nMeasures];
			setResult(column, v, value);
			}
	}
}
updateResults;

//Create flattened image
selectImage(originalimage);
roiManager("Show All without labels");
run("From ROI Manager");
//Overlay made part of pixel data
run("Flatten");
flatCopy = getImageID();
selectImage(flatCopy);
imagenametext = withoutextension[0];
rename(imagenametext+"_Result");
result = getTitle;
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Append, Skip or Exit option
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
items = newArray("Append result and continue", "Skip this image", "Exit");
Dialog.create("Check Results");
Dialog.addMessage("Choose an option");
Dialog.addRadioButtonGroup("Options:", items, 3, 1, items[0]);
Dialog.show;
answer = Dialog.getRadioButton();

if (answer=="Append result and continue") {
//Batch results table manipulations
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
overallresults = "Batch Results";
if (isOpen(overallresults)) {
//Close the results table from the current image
selectWindow("Results");
run("Close");
IJ.renameResults(overallresults, "Results");//so we can append the new values to the existing table
rowCount = nResults;//Get the current number of rows in the table, used below
//Use flatArray again, extract the results of the new image to the table 
for (c=0; c<counter; c++) {
	for (v=0; v<manager; v++) {
		for (m=0; m<nMeasures; m++) {	
			column = resultheadings[c] + "_" + measurementheadings[m];
			value = flatArray[m + v*nMeasures + c*manager*nMeasures];
			test = m + v*nMeasures + c*manager*nMeasures;
			rowCountIncrement = rowCount+v;//exisitng number of rows + v
			setResult(column, rowCountIncrement, value);
			}
		}	
	}
IJ.renameResults(overallresults);
}
else {
selectWindow("Results");
IJ.renameResults(overallresults);
}

//Save images
saveAs("Tiff", dir2+result);
run("Close All");
roiManager("reset");
}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
else if (answer=="Skip this image") {//see radio button dialog above
	run("Close All");
	selectWindow("Results");
	run("Close");
	roiManager("reset");
}

else {//see radio button dialig above
roiManager("reset");
exit();	
}

//End of open files loop
}
//Save results table
selectWindow(overallresults);
saveAs("Batch Results", dir2+"Batch Results.xls");
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////