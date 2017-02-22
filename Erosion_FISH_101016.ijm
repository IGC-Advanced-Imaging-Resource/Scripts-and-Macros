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
//User input for channel order. Number input is absolute value
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
run("Gaussian Blur...", "sigma=4");  //Add this if nucleus has chromatin dense regions and segmentation of boundary fails
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
run("Analyze Particles...", "size=5-Infinity include add");
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
//Erode the nucleus until the area becomes equal to 4/5 total area
//loop to obtain 5 shell selections
current_area=nuclear_area;
//Run this loop 5 times as there needs to be 5 shells
for (i=0; i<4; i++){
//for each of the 5 shells work out its required area by eroding
//and comparing to total area	
for (j=0; j<totalsegs; j++) {
//For each shell keep eroding until area equals 4/5s, then 3/5s etc 
	while (current_area>seg_area[i]) {
	setOption("BlackBackground", false);
    //run("Gray Morphology", "radius=5 type=[free form] operator=erode text1=[ 0 255 255 255 0  255 255 255 255 255  255 255 255 255 255  255 255 255 255 255  0 255 255 255 0 ]");
    run("Erode");
    run("Create Selection");
    run("Measure");
    current_area = getResult("Area", 0);
    run("Clear Results");	
	}
}
//When each shell area determined add it to ROI Manager
roiManager("Add");

//Would make each shell a different colour not currently implemented
//roiManager("Select", i);
//roiManager("Set Color", colour[i]);
//print(current_area);
}
//roiManager("Select", i);
//roiManager("Set Color", "red");
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
//Spot selection and processing
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//Circular selection brush of defined size, holding shift adds additional selections.
//but they are all part of the same single selection
run("Tile");
setTool("brush");
call("ij.gui.Toolbar.setBrushSize", 30);
waitForUser("Spot selection: \n Hold shift to mark multiple spots on the same image");

analysisChannels = channelId.length-1;//Analyse all channels - DAPI
manager = roiManager("Count");
flatArray = newArray(2 + manager * analysisChannels);//Calculate how many elements needed in the array
flatArray[0] = imagenametext;//1st entry in array should be the file name
flatArray[1] = nucArea;//2nd entry in array should be the nucleus area
z = 2;//Start adding to the array from index 2 as 0 & 1 are already occupied

setBatchMode(true);
for (i=1; i<channelId.length; i++) {
selectImage(channelId[i]);
if (type==24) {
run("Find Maxima...", "noise=50 output=[Single Points]");//noise value is dependent on data type (spot finding)
}
else {
run("Find Maxima...", "noise=2000 output=[Single Points]");	
}
run("Invert");
setAutoThreshold("Default dark");
	for (w=0; w<manager; w++) {	
	roiManager("Select", w);//Select each ROI (shell)
	run("Analyze Particles...", "size=0-1 pixel include summarize");//Produce summary table that gives a count of the no. of spots per shell
	IJ.renameResults("Summary", "Results");//Rename summary table to results so count value can be extracted
	flatArray[z++] = getResult("Count", 0);//Add the number of spots found in each shell to the array
	
	}
selectImage(channelId[i]);
roiManager("Show All without labels");
run("From ROI Manager");
}
selectWindow("Results");
run("Close");
setBatchMode(false);
//Array.print(flatArray);
	
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//Produce the results table for current image
setResult("File Name", 0, flatArray[0]);//The first results table column 
setResult("Nucleus Area", 0, flatArray[1]);//DAPI Area
updateResults;
a = 2;
for (i=1; i<channelId.length; i++) {//i=1 because DAPI channel is 0 and should be ignored
	for (b=0; b<manager; b++) {
	column = resultheadings[i] + "_" + b+1;//w+1 enables shell column headings to be 1-5 instead of 0-4
	value = flatArray[a];//Ignore elements 0 & 1 or array, start at 2
	a = a+1;
	//print(a);
	setResult(column, 0, value);
	}
}
updateResults;
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Produce flattened image
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
setResult("File Name", rowCount, flatArray[0]);//The first results table column 
setResult("DAPI", rowCount, flatArray[1]);//DAPI Area
updateResults;
a = 2;
for (i=1; i<channelId.length; i++) {//i=1 because DAPI channel is 0 and should be ignored
	for (b=0; b<manager; b++) {
	column = resultheadings[i] + "_" + b+1;//w+1 enables shell column headings to be 1-5 instead of 0-4
	value = flatArray[a];//Ignore elements 0 & 1 or array, start at 2
	a = a+1;
	//print(a);
	setResult(column, rowCount, value);
	}
}
IJ.renameResults(overallresults);
}

else {
selectWindow("Results");
IJ.renameResults(overallresults);	
}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Prepare images for saving
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
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
roiManager("reset");
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////