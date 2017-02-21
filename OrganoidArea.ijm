// A Script that quantifies areas of organoids acquired on EVOS system
// Language: ImageJ Macro
// Authors: Ahmed Fetit
// Advanced Imaging Resource, HGU, IGMM.
// Updated: 2/12/2015/

imagename = getTitle();

//Setting scale using information of the scalebar on the image
run("Set Scale...", "distance=444 known=1000 unit=microns");

//Images are RGB screenshots but thresholding them directly works fine
run("Threshold...");
waitForUser("Complete thresholding then press OK");

run("Analyze Particles...", "size=10000-Infinity pixel add");

waitForUser("In ROI manager, select organoid of interest");
run("Set Measurements...", "area perimeter limit redirect=None decimal=3");
run("Measure");

Area = getResult("Area",0);

print(imagename+", "+Area);

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
if (isOpen("Results"))
{
     selectWindow("Results");
     run("Close");
}