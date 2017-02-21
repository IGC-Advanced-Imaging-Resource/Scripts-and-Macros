// A Script that quantifies number of colonies
// Language: ImageJ Macro
// Authors: Ahmed Fetit
// Imaging Resource, HGU, IGMM.
// Updated: 14/10/2015/

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

selectImage(ch[1]);
close()

selectImage(ch[2]);

waitForUser("Make binary?");
setOption("BlackBackground", false);
run("Make Binary");


run("Specify...", "width=2142 height=2166 x=640 y=480 oval");
waitForUser("Place oval ROI on desired region, then press OK");
run("Watershed");

run("Analyze Particles...", "size=100-2000 pixel show=Masks display summarize add");

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