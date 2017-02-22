//This macro will measure distances between selected FISH probe pairs/triplets on all images within a folder
//It can handle 3 and 4 channel images and RGB or 16bit micro-manager stack images
//The images have to be pre-calibrated with the right µm/pixel value a message reminds you of this at the start
//You can choose to only measure between two or three probe colours e.g. skip TxRd channel but measure distance from FITC to Cy5
//Your choice is then applied in batch across all images in the folder
//When inputting the channel order at the start, put zero in the box if you don't want to include that channel.  DAPI has to be included

//Opening and preparation steps
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
run("Plots...", "width=450 height=200 font=12 minimum=0 maximum=0 sub-pixel");//ensures sub-pixel measurements are made from line selections
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
Dialog.addNumber("Cy5", 4);//Add another number for 5 colour FISH
Dialog.show;
//Channel order output
order = newArray(4);//5 for 5 colour FISH
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
resultheadings = newArray(counter);//stores the names of the channels present in the image
channelId = newArray(counter);//Array to store channel ids
//Add additional channel name for 5 colour FISH
names = newArray("DAPI", "FITC", "TxRd", "Cy5");//All possible channel strings
x = 0;//starting index for resultheadings array
q = 0;//Starting index for channelId array
for (i=0; i<order.length; i++) {
	if (order[i] != 0) {
	Stack.setChannel(order[i]);//for the dialog inputs that weren't zero duplicate those channels
	run("Duplicate...", " ");
	channelId[q++] = getImageID;//store the image id in an array
	selectImage(duplicate);//make this image active for the next loop interation	
	resultheadings[x++]=names[i];//store the name of the next channel
	}
else {
	i+1;//skip this channel and increment counter
	}
}
//Array.print(resultheadings);
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Nucleus processing
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
run("Colors...", "foreground=white background=white selection=white");//line colour
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
run("Set Measurements...", "area add redirect=None decimal=0");
run("Analyze Particles...", "size=5-Infinity include add");
//run("Create Selection");
nuclear_area = getResult("Area", 0);
nuclear_area = round(nuclear_area);
run("Clear Results");
//selectImage(channelId[0]);
resetThreshold();
selectImage(originalimage);
roiManager("select", 0);
run("Add Selection...");
//roiManager("select", 0);
roiManager("delete");
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Spot selection and processing
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
selectImage(duplicate);
setTool("brush");
call("ij.gui.Toolbar.setBrushSize", 25);
waitForUser("click on spot pairs(s) (hold Shift to select multiple), press t key for single ROI");//press t key for a single ROI
count = roiManager("Count");
if (count!=1) {//Making two selections on the image using shift key is called a composite selection.
	//It appears in the ROI manager as one entry but they need to be processed separately so need to split them into more than one ROI in the manager
roiManager("Split");//brush allows multiple selections but the roiManager see's them as one
//so split divides each selection into its own roi for processing
}
else {}//User has pressed t key and only one ROI on image (one spot pair to be analysed). No need to run split command
selectImage(duplicate);
close;
run("Set Measurements...", "area center limit redirect=None decimal=2");//find center of mass
manager = roiManager("Count");
channels = counter-1;//all except dapi channel
centers = newArray(manager*channels*2);//Stores the centre's of massess = number of ROI's x spot channels x 2 (xm and ym)
x = 0;
for (m=0; m<manager; m++) {//for each roi	
	for (i=1; i<counter; i++) {//select each channel image
	selectImage(channelId[i]);
	roiManager("select", m);
	setAutoThreshold("Otsu dark");
	run("Analyze Particles...", "size=0.01-Infinity clear include");//size parameters may need to change
	Area = newArray(nResults);//store the areas of found spots in the same channel
	Biggest = newArray(nResults);
	for (q=0; q<nResults; q++) {//for the number of spots found
	Area[q] = getResult("Area", q);//Extract each area from the results table
	Biggest = Array.rankPositions(Area);//Creates an array with the areas listed in ascending size order
	}//biggest-1 is equivalent to the last index in the Biggest array which will contain the centroids of the largest spot
	centers[x++] = getResult("XM", Biggest.length-1);//array order is ROI, channel, xm, ym (same as results table columns will be)
	centers[x++] = getResult("YM", Biggest.length-1);//These are calibrated values, i.e. in µm
	}
}
roiManager("reset");//clear ROI's for new line ROI's
//Array.print(centers);
selectImage(originalimage);
getPixelSize(unit, pixelWidth, pixelHeight);//image calibration


x = 0;
if (counter-1==2) {//For images with 2 spot channels, counter is number of channels present so counter is channels-DAPI channel. I.e. 2 spot channels
	for (i=0; i<manager; i++) {
	makeLine(centers[x++]/pixelWidth, centers[x++]/pixelWidth, centers[x++]/pixelWidth, centers[x++]/pixelWidth);//pixelWidth or height is used otherwise line will be drawn based on pixels not µm 
	Roi.setStrokeWidth(1);//line thickness
	roiManager("add");//Add the lines to the manager for later length measuring run("Draw", "slice");
	}
}
else {//For images with 3 spot channels 
	  for (i=0; i<manager; i++) {//number of ROIs x 3 (3 lines needed per ROI) 
	  x = i * 6;
	  makeLine(centers[x++]/pixelWidth, centers[x++]/pixelWidth, centers[x++]/pixelWidth, centers[x++]/pixelWidth);
	  Roi.setStrokeWidth(1);//line thickness
	  roiManager("add");//Add the lines to the manager for later length measuring run("Draw", "slice");
	  x = i * 6;
	  makeLine(centers[x++]/pixelWidth, centers[x++]/pixelWidth, centers[x+2]/pixelWidth, centers[x+3]/pixelWidth);
	  Roi.setStrokeWidth(1);//line thickness
	  roiManager("add");//Add the lines to the manager for later length measuring run("Draw", "slice");
	  makeLine(centers[x++]/pixelWidth, centers[x++]/pixelWidth, centers[x++]/pixelWidth, centers[x++]/pixelWidth);
	  Roi.setStrokeWidth(1);//line thickness
	  roiManager("add");//Add the lines to the manager for later length measuring run("Draw", "slice");
	 	}
}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//Produce an image that has all line selections permanently applied
roiManager("show all without labels");
run("From ROI Manager");
run("Flatten");
flat = getImageID;

//Produce the headings for the results table columns
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
x = 0;
//if 2 spot channels, one distance column needed
if (counter-1==2) {//counter is total number of present channels
	columntitles = newArray(1+counter-1);
	columntitles[x++] = "Filename";
	columntitles[x++] = "Nucleus Area";
	columntitles[x++] = resultheadings[1] + " to " + resultheadings[2] + " distance";//e.g. FITC to TxRd distance
}
//if 3 spot channels, 3 distance columns needed
else if (counter-1==3) {
	columntitles = newArray(2+counter-1);
	columntitles[x++] = "Filename";
	columntitles[x++] = "Nucleus Area";
	columntitles[x++] = resultheadings[1] + " to " + resultheadings[2] + " distance";
	columntitles[x++] = resultheadings[1] + " to " + resultheadings[3] + " distance";
	columntitles[x++] = resultheadings[2] + " to " + resultheadings[3] + " distance";
}
//Add an else (counter-1==4), columntitles = newArray(3+counter-1) to include 5 colour FISH images
//Array.print(columntitles);
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Measure the spot distances & store them
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
managerTwo = roiManager("Count");//The number of lines/distances
lengths = newArray(managerTwo);
x = 0;
run("Set Measurements...", "feret's redirect=None decimal=2");
for (i=0; i<managerTwo; i++) {
	roiManager("select", i);
	run("Measure");
	lengths[x++] = getResult("Length", i);//Select the line selections in the ROI manager and measure their lengths into the array "Lengths"
}
selectWindow("Results");
run("Close");
roiManager("reset");
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Produce the results table from the current image
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
defaultValues = newArray(2);//Array to store filenames and areas. defaultValues & Values arrays will be joined in results later
defaultValues[0] = imagenametext;
defaultValues[1] = nuclear_area;

values = newArray(lengths.length);//Array to store the distances
for (i=0; i<values.length; i++) {
	values[i] = lengths[i];
}
//Array.print(defaultValues);
//Array.print(values);
//Fill the first two columns of results table with the default values (filename, area)
for (i=0; i<manager; i++) {//manager is the number of spot pairs
	for (m=0; m<2; m++) {
	column = columntitles[m];
	setResult(column, i, defaultValues[m]);
	}
}
//Fill column 2+ with the distance measurements from each channel
x = 0;
for (i=0; i<manager; i++) {
	for (m=2; m<columntitles.length; m++) {
	column = columntitles[m];
	setResult(column, i, values[x++]);
	}
}
updateResults;//Show the updated results table

rows = nResults;
x = 0;
flatArray = newArray(rows * columntitles.length);//Store the current images results in an array
//Add these values on to the overall results table if it exists
for (i=0; i<nResults; i++) {
	for (m=0; m<columntitles.length; m++) {
	column = columntitles[m];
		if (m==0) {//First column always contains a string (image filename)
		flatArray[x++] = getResultString(columntitles[m], i);//To extract a string from the results table you must use getResultString	
		}	
		else {
		flatArray[x++] = getResult(columntitles[m], i);	
		}
	}
}
//Array.print(flatArray);
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Append, Skip or Exit option
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
run("Tile");
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
//add the results from the current image to the existing overallresults table using flatArray
x = 0;
for (i=0; i<rows; i++) {//the number of rows in the current images results table
	for (m=0; m<columntitles.length; m++) {
		column = columntitles[m];
		setResult(column, rowCount, flatArray[x]);
		x = x+1;//Increment the position in the array
		}
rowCount = nResults;
}
updateResults;
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
selectImage(flat);
imagenametext = withoutextension[0];
rename(imagenametext+"_Result");
result = getTitle;

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
}

else {//see radio button dialig above
roiManager("reset");
exit();	
}


//End of image opening loop
}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Save final batch results table
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
selectWindow(overallresults);
saveAs("Batch Results", dir2+"Batch Results.xls");
roiManager("reset");
selectWindow("ROI Manager");
run("Close");