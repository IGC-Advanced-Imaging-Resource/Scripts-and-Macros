//This macro measures 3 parameters, nucleus area, FISH probe centre of mass to nucleus periphery and nucleus centre of mass to periphery (to same periphery coords as probe)
//Input images can be 16bit stack or 24bit RGB
//Images can have up to 4 channels and any number of probes in each channel can be measured
//If you choose not to paint probes on one channel image it will be closed
//Macro expects images to have a µm calibration (this should already be applied to Micro-Manager images)
//Images to be analysed must be stored in a single folder

//Install a macro that allows the "o" key to be used to add selections with a single click.  If this macro isn't implemented you have to paint a selection bigger
//than the width of the pre-defined selection then press b key.
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
str = 'macro "Add Overlay [o]" {\n'
 str = str + 'run("Add Selection...");\n';
 str = str + 'run("Select None");\n}';
 path=getDirectory("imagej")+"/macros/addOverlay.ijm";
 File.saveString(str, path);
 run("Install...", "install=["+path+"]");
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////


//Opening and preparation steps
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
run("Plots...", "width=450 height=200 font=12 minimum=0 maximum=0 sub-pixel");
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
channelnames = newArray(counter);//stores the names of the channels present in the image
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
	channelnames[x++] = names[i];//stores which channels are potentially to be analysed
	}
else {
	i+1;//skip this channel and increment counter
	}
}
print("The channels present in this image are:");
Array.print(channelnames);
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Nucleus Area and boundary calculations
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
run("Colors...", "foreground=white background=white selection=white");//line colour
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
run("Set Measurements...", "area center limit add redirect=None decimal=0");
run("Analyze Particles...", "size=5-Infinity include add");
Nuc_COMx = getResult("XM", 0);//Nucleus center of mass coords
Nuc_COMy = getResult("YM", 0);
print("The nucleus COM is at x coord " + Nuc_COMx);
print("The nucleus COM is at y coord " + Nuc_COMy);
nuclear_area = getResult("Area", 0);
nuclear_area = round(nuclear_area);
print("The nucleus area is " + nuclear_area + "µm");
run("Clear Results");
//selectImage(channelId[0]);
resetThreshold();
selectImage(originalimage);
roiManager("select", 0);//Select the nuclear boundary selection
getSelectionCoordinates(xpoints, ypoints);//Produces 2 arrays containing the coordinates of the selected selection.  The values are in pixels (not µm)
run("Add Selection...");//Add the boundary to the image as an overlay for display purposes later
roiManager("delete");
selectImage(originalimage);
getPixelSize(unit, pixelWidth, pixelHeight);//image calibration, needed to make lines
print("The image calibration is " + pixelWidth + "µm");
selectImage(duplicate);
close;
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Rename windows
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
for (i=0; i<counter; i++) {
	selectImage(channelId[i]);
	run("Enhance Contrast", "saturated=0.1");
	run("Grays");
	rename(channelnames[i]);
}
selectImage(channelId[0]);//Close the DAPI image, no longer needed
close;
counter = counter-1;//DAPI image closed and no longer to be counted
for (i=0; i<counter; i++) {
	channelId[i] = channelId[i+1];//Adjust index of channelId array so first probe channel is channelId[0], aids with subsequent loops that start at zero
}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Probe selection and processing
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
run("Tile");
setTool("brush");
call("ij.gui.Toolbar.setBrushSize", 20);
centers = newArray(100);//store the COM's for every spot 
x = 0;
overlaycounter = newArray(nImages-1);//length of array is how many of the windows have overlays, assumes if window is open it has overlays hence nImages. -1 to exclude original merge
waitForUser("Select a probe then press o key");//press t key for a single ROI
//Determine which channels have overlays and rearrange image id array
u = 0;
for (i=0; i<counter; i++) {//For the possible analysis channels
	selectImage(channelId[i]);
	overlay = Overlay.size;//Check for overlays
	if (overlay==0) {//If no overlays, channel not to be analysed, close it
	close;	
	}
else {
	channelId[u] = getImageID();//If image has overlays change imageId index to ensure it starts at zero i.e. so selectImageID(channelId[i])
	//works from zero when performing loops lower down
u = u+1;
	}
}
counter = nImages-1;
//Loop through channels 
for (i=0; i<counter; i++) {
selectImage(channelId[i]);//Select next channel after DAPI which has been closed
run("To ROI Manager");//Move the overlays added by the user (b key) to the ROIManager for processing
overlaycounter[i] = roiManager("Count");//for each channel count the number of ROI's in the manager
run("Set Measurements...", "area center limit redirect=None decimal=2");//find center of mass
	for (m=0; m<overlaycounter[i]; m++) {//for each roi	
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
roiManager("reset");//clear ROI's for ready for next channel
roiManager("show all without labels");	
	}//loop end for getting the coords of centroids from each channel

//This code block calculates how many overlays (ROI's) there are in total and trims down the centers array
//so that it is only as long as the number of center of mass coordinates 
//////////////////////////////////////////////////////////////////////////////////
totaloverlays = 0;
for (i=0; i<lengthOf(overlaycounter); i++) {//For each element in the array, sum them, this tells us the total number of overlays that have been added to all images
	totaloverlays = totaloverlays + overlaycounter[i];
}
totaloverlays = totaloverlays * 2;//Multiply the totaloverlays by 2 as there are 2 coords (x & y) per probe 
//print(totaloverlays);
centers = Array.trim(centers, totaloverlays);//Reduce the size of the array down so it is only as long as the number of coords held
print("These are the coordinates of the probes:"); 
Array.print(centers);
//////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Probe centre to nucleus edge & nucleus centre to edge calculations
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
run("Set Measurements...", "feret's redirect=None decimal=2");//set to measure length
all_Lengths = newArray(xpoints.length);//store each spots centre to every point on nucleus boundary
probe_Lengths = newArray(centers.length/2);//Array to store the distances of probe to nearest edge
nuc_cent_edge_Lengths = newArray(centers.length/2);//Array to store the distances of nucleus COM to nearest edge
channeltitles = newArray(counter);//Store the names of the channels analysed, use to make results table column headings
z = 0;
q = 0;
s = 0;
for (i=0; i<counter; i++) {//for each channel
	selectImage(channelId[i]);
	title = getTitle;
	channeltitles[i] = title;//Store name of current channel for use making results table
	for (a=0; a<overlaycounter[i]; a++) {//for each ROI
		for (b=0; b<xpoints.length; b++) {//for each boundary coord
		makeLine(centers[z]/pixelWidth, centers[z+1]/pixelWidth, xpoints[b], ypoints[b]);//make lines between each boundary coord and the current probe
		run("Measure");//Measure the length of every line
		all_Lengths[b] = getResult("Length", b);//Put these length measurements into the array
		}//end of boundary coord loop
	run("Clear Results");
	ranks = Array.rankPositions(all_Lengths);//An array containing the index positions of the array nuc_Lengths, ranked with the index that contains the smallest distance measurement.  
	makeLine(centers[z]/pixelWidth, centers[z+1]/pixelWidth, xpoints[ranks[0]], ypoints[ranks[0]]);//We know ranks[0] contains smallest distance value
	z = z+2;//increment to the next set of probe xy coords
	run("Add Selection...");//Add the line from centroid to periphery to the image as an overlay for display purposes later
	run("Measure");
	roiManager("add");
	probe_Lengths[q++] = getResult("Length", 0);//Store the shortest distances for each spot ready for adding to results table later. 
	run("Clear Results");
	makeLine(Nuc_COMx/pixelWidth, Nuc_COMy/pixelWidth, xpoints[ranks[0]], ypoints[ranks[0]]);
	run("Add Selection...");//Add the line from centroid to periphery to the image as an overlay for display purposes later
	run("Measure");
	roiManager("add");
	nuc_cent_edge_Lengths[s++] = getResult("Length", 0);//Store the coords of nearest edge to the current probe
	run("Clear Results");
	print("The spot centroid to nearest nuclear edge distance is " + probe_Lengths[q-1] + "µm");//sanity check
	print("The nucleus centroid to nearest nuclear edge distance is " + nuc_cent_edge_Lengths[s-1] + "µm");//sanity check
	}//end of overlays per channel loop
roiManager("show none");	
title = getTitle;
//print(title);
run("Flatten");
rename(title);
selectImage(channelId[i]);
close;
}//end of channels loop
selectWindow("Results");
run("Close");
selectImage(originalimage);
run("From ROI Manager");
run("Flatten");
flat = getImageID;
print("The probe-periphery distances are shown below:");
Array.print(probe_Lengths);
print("The nucleus-periphery distances are shown below:");
Array.print(nuc_cent_edge_Lengths);
run("Tile");
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//Produce results tables for current image
f = 0;
for (i=0; i<counter; i++) {
	for (a=0; a<overlaycounter[i]; a++) {
		setResult("Filename", f, withoutextension[0] + "_" + channeltitles[i]);
		setResult("Nucleus Area (µm)", f, nuclear_area);
		setResult("P to E (µm)", f, probe_Lengths[f]);
		setResult("N to E (µm)", f, nuc_cent_edge_Lengths[f]);
	f = f+1;
	}

}
updateResults();
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
f = 0;
for (i=0; i<counter; i++) {
	for (a=0; a<overlaycounter[i]; a++) {
		setResult("Filename", rowCount, withoutextension[0] + "_" + channeltitles[i]);
		setResult("Nucleus Area (µm)", rowCount, nuclear_area);
		setResult("P to E (µm)", rowCount, probe_Lengths[f]);
		setResult("N to E (µm)", rowCount, nuc_cent_edge_Lengths[f]);
	f = f+1;
	updateResults();
	rowCount = nResults;
	}
updateResults();
//rowCount = nResults;
}
updateResults();
IJ.renameResults(overallresults);
}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

else {
selectWindow("Results");
IJ.renameResults(overallresults);	
}
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
	roiManager("reset");
}

else {//see radio button dialig above
roiManager("reset");
exit();	
}
}//End of image opening loop
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////

//Save final batch results table
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
selectWindow(overallresults);
saveAs("Batch Results", dir2+"Batch Results.xls");
roiManager("reset");
selectWindow("ROI Manager");
run("Close");                                                                      