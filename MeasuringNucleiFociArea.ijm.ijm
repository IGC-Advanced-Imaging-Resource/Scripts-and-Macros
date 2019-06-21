// A script that quantifies area of foci 
// First a user defined threshold is used to isolate foci
// Then the user selects the cell where they wish to count the foci
// Analyze particles tool is then used to measure the number and area of the foci
// Authors: Ahmed Fetit
// Advanced Imaging Resource, HGU, IGMM.
// Updated: 11/08/2016/

imagename = getTitle();
run("Set Scale...", "distance=1 known=0.102 pixel=1 unit=µm");
selectWindow(imagename);
run("Split Channels");

selectImage(3);

waitForUser("Threshold foci?");
run("Threshold...");
waitForUser("Press OK when finished thresholding");

setTool(0);
waitForUser("Click shift and select ROIs where cell is. When finished, press OK");

run("Set Measurements...", "area limit display add redirect=None decimal=2");
waitForUser("Get area of foci?");
run("Analyze Particles...", "size=20-350 pixel display clear summarize add");

if (isOpen("ROI Manager"))
{
     selectWindow("ROI Manager");
     run("Close");
}

