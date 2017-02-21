// A Script that quantifies the number of foci on TRITC based on cells identified on DAPI
// Language: ImageJ Macro
// Authors: Ahmed Fetit
// Advanced Imaging Resource, HGU, IGMM.
// Updated: 30/10/2015/

imagename = getTitle();
selectWindow(imagename);
run("Split Channels");
channels=3;
ch = newArray(channels);
ch0 = getImageID;

for (i=0; i<channels; i++)
{
	ch[i] = ch0+i;
}

//Select DAPI
selectImage(ch[0]);

waitForUser("Threshold DAPI?");
run("Threshold...");
waitForUser("Press OK when finished thresholding");
run("Analyze Particles...", "size=100-Infinity add");
run("Clear Results"); 


for (i=0 ; i<roiManager("count"); i++) 
{
	selectImage(ch[0]);
	roiManager("select", i); //select cell from manager
    run("Measure"); // get measurements e.g. area
}
//Export cell statistics results as CSV
selectWindow("Results"); 
saveAs("Text", "\\\\cmvm.datastore.ed.ac.uk\\cmvm\\smgphs\\users\\afetit\\Win7\\Desktop\\"+imagename+"CellStats.csv");

run("Clear Results");

//Loop through cells, get maxima of each
for (i=0 ; i<roiManager("count"); i++) 
{
    selectImage(ch[2]);
    roiManager("select", i);
    run("Find Maxima...", "noise=10 output=Count");
}
//Export maximum intensity results as CSV
selectWindow("Results"); 
saveAs("Text", "\\\\cmvm.datastore.ed.ac.uk\\cmvm\\smgphs\\users\\afetit\\Win7\\Desktop\\"+imagename+"FociStats.csv");

//Create an image that shows maxima on all cells
selectImage(ch[2]);
roiManager("Show All with labels");
roiManager("Combine");
run("Find Maxima...", "noise=10 output=[Point Selection]");
run("Flatten");//to take a screenshot for export
saveAs("Tiff", "\\\\cmvm.datastore.ed.ac.uk\\cmvm\\smgphs\\users\\afetit\\Win7\\Desktop\\"+imagename+"Maxima.tiff");


waitForUser("Close ROI Manager?");
if (isOpen("ROI Manager"))
{
     selectWindow("ROI Manager");
     run("Close");
}

waitForUser("Close Windows?");
while (nImages>0) 
{ 
     selectImage(nImages); 
     close(); 
} 
