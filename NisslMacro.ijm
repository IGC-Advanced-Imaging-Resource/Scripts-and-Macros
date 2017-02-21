// A Script that quantifies Nissl staining within an ROI (better than Definiens)
// Language: ImageJ Macro
// Authors: Ahmed Fetit
// Imaging Resource, HGU, IGMM.
// Updated: 11/1/2016/

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

//Select and duplicate Green channel
selectImage(ch[0]);
close()

selectImage(ch[2]);
close()

selectImage(ch[1]);


setOption("BlackBackground", false);
run("Threshold...");
waitForUser("After thresholding click on OK!");

run("Specify...", "width=1879 height=1271 x=3033 y=929 slice=1");
waitForUser("Place oval ROI on desired region, then press OK");
//run("Watershed");

run("Analyze Particles...", "size=50-3000 pixel show=Outlines display exclude summarize add");

waitForUser("Close ROI manager and Results?");
if (isOpen("ROI Manager"))
{
     selectWindow("ROI Manager");
     run("Close");
}

if (isOpen("Results"))
{
     selectWindow("Results");
     run("Close");
}