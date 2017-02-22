//DAPI stained chromosomes when represented as blue in coloured images are difficult to discern
//against a dark background.  This script modifies the appearance of DAPI stained chromosomes by mixing
//a proportion of the DAPI image equally into both red and green colour planes, and then re-merging these
//with the original blue colour plane.
//Input image must be 24bit colour and contain red, green and blue channels
//There is an option in the macro to crop to a ROI

//Create and show the ROI dialog
Dialog.create("ROI Option");
Dialog.addMessage("Check the box for a ROI only");
Dialog.addCheckbox("ROI", 0);
Dialog.show;
ROI = Dialog.getCheckbox;
if (ROI==1) {
//Wait for the user to draw the ROI
setTool("rectangle");
waitForUser("Draw the ROI on the image");
run("Crop");
}
else {}
//Steps to allow id and manipulation of the original channel windows once split.
/////////////////////////
setBatchMode(true);
original = getImageID;
//print(original);
name = getTitle;
channelId = newArray(3);
r = 2;
for (i=1; i<4; i++) {
channelId[r] = original-i;	
r = r-1;
	}
run("Split Channels");
/////////////////////////
//Some variables
pc_inc = 0;//v133
pc_dec = 1;//v134

for (i=0; i<7; i++) {
pc_inc = pc_inc+0.1;
pc_dec = pc_dec-0.1;

////////////////////////////////////////////////////////
//Red image processing
selectImage(channelId[2]);//red
run("Duplicate...", " ");
rename("red_dup");
//multiply all pixels in red image by 0.9 (loop 0), 0.8 (loop 1) etc
run("Multiply...", "value=["+pc_dec+"]");
selectImage(channelId[0]);//blue
run("Duplicate...", " ");
rename("blue_dup");
//multiply all pixels in the duplicated blue image by 0.1 (loop 0), 0.2 (loop 1) etc
run("Multiply...", "value=["+pc_inc+"]");
//Add the altered red and blue images together
imageCalculator("Add create", "red_dup", "blue_dup");
rename("red");
selectWindow("blue_dup");
close;
//Green image processing
//steps as above but replace red with green image
selectImage(channelId[1]);
run("Duplicate...", " ");
rename("green_dup");
run("Multiply...", "value=["+pc_dec+"]");
selectImage(channelId[0]);//blue
run("Duplicate...", " ");
rename("blue_dup");
//multiply all pixels in the duplicated blue image by 0.1 (loop 0), 0.2 (loop 1) etc
run("Multiply...", "value=["+pc_inc+"]");
imageCalculator("Add create", "green_dup", "blue_dup");
rename("green");
/////////////////////////////////////////////////////// 

//Duplicate the original blue image so we don't merge the original which is needed in subsequent loops
selectImage(channelId[0]);
run("Duplicate...", " ");
rename("blue");
//Merge the results of the multiplication and addition
run("Merge Channels...", "c1=[red] c2=[green] c3=[blue]");
selectWindow("RGB");
rename(name + "_" + pc_inc + "_" + pc_dec);
selectWindow("red_dup");
close;
selectWindow("green_dup");
close;
selectWindow("blue_dup");
close;
}

for (i=0; i<channelId.length; i++) {
	selectImage(channelId[i]);
	close;
}
setBatchMode("exit and display");
run("Tile");