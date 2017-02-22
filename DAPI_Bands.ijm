//If DAPI staining is too uniform to permit unequivocal identification of chromosomes,
//linear filters can be employed to improve the mid range contrast of chromosome bands.
//This script uses a series of crispening convolutions to improve DAPI banding.
//You can run the macro on a ROI only by drawing the roi on the image then select Image>Crop before running the macro

//Stores the radio button options
items = newArray("Tile", "Stack");
//Create user input dialog
Dialog.create("Output");
Dialog.addMessage("Tile-Shrinks images to fit screen");
Dialog.addMessage("Stack-leaves images full size");
Dialog.addRadioButtonGroup("Output Option", items, 2, 1, items[0]);
Dialog.show;
result = Dialog.getRadioButton;

setBatchMode(true);
originalImage = getImageID;
rename("Original");
//Store the window names for the new images
names = newArray("Small soft", "Medium soft", "Large soft", "Small moderate", "Medium moderate", "Large moderate", "Small hard", "Medium hard", "Large hard");
//The list of convolution kernels used
convolutions = newArray ("text1=[0 0 0 0 0\n0 -1 -1 -1 0\n0 -1 12 -1 0\n0 -1 -1 -1 0\n0 0 0 0 0\n] normalize", "text1=[0 0 -1 0 0\n0 -1 1 -1 0\n-1 1 8 1 -1\n0 -1 1 -1 0\n0 0 -1 0 0\n] normalize", "text1=[-1 -1 -1 -1 -1\n-1 2 2 2 -1\n-1 2 8 2 -1\n-1 2 2 2 -1\n-1 -1 -1 -1 -1\n] normalize", "text1=[0 0 0 0 0\n0 -1 -1 -1 0\n0 -1 10 -1 0\n0 -1 -1 -1 0\n0 0 0 0 0\n] normalize", "text1=[0 0 -1 0 0\n0 -1 1 -1 0\n-1 1 6 1 -1\n0 -1 1 -1 0\n0 0 -1 0 0\n] normalize", "text1=[0 0 -1 0 0\n0 -1 1 -1 0\n-1 1 6 1 -1\n0 -1 1 -1 0\n0 0 -1 0 0\n] normalize", "text1=[-1 -1 -1 -1 -1\n-1 2 2 2 -1\n-1 2 4 2 -1\n-1 2 2 2 -1\n-1 -1 -1 -1 -1\n] normalize", "text1=[0 0 0 0 0\n0 -1 -1 -1 0\n0 -1 9 -1 0\n0 -1 -1 -1 0\n0 0 0 0 0\n] normalize", "text1=[-1 -1 -1 -1 -1\n-1 2 2 2 -1\n-1 2 2 2 -1\n-1 2 2 2 -1\n-1 -1 -1 -1 -1\n] normalize");
//Run each kernel in turn on the original image
for (i=0; i<9; i++) {
	selectImage(originalImage);
	run("Duplicate...", " ");
	rename(names[i]);
	run("Convolve...", "text1=["+convolutions[i]+"] normalize stack");
}
setBatchMode("exit and display");
//Determines is user pressed Tile or Stack in the dialog
if (result=="Tile") {
	run("Tile"); 
}
else {
	run("Cascade");
}

//Small soft
//0 0 0 0 0\n0 -1 -1 -1 0\n0 -1 12 -1 0\n0 -1 -1 -1 0\n0 0 0 0 0\n

//Medium soft
//0 0 -1 0 0\n0 -1 1 -1 0\n-1 1 8 1 -1\n0 -1 1 -1 0\n0 0 -1 0 0\n

//Large soft
//-1 -1 -1 -1 -1\n-1 2 2 2 -1\n-1 2 8 2 -1\n-1 2 2 2 -1\n-1 -1 -1 -1 -1\n

//Small moderate
//0 0 0 0 0\n0 -1 -1 -1 0\n0 -1 10 -1 0\n0 -1 -1 -1 0\n0 0 0 0 0\n

//Medium moderate
//0 0 -1 0 0\n0 -1 1 -1 0\n-1 1 6 1 -1\n0 -1 1 -1 0\n0 0 -1 0 0\n

//Large moderate
//-1 -1 -1 -1 -1\n-1 2 2 2 -1\n-1 2 4 2 -1\n-1 2 2 2 -1\n-1 -1 -1 -1 -1\n

//Small hard
//0 0 0 0 0\n0 -1 -1 -1 0\n0 -1 9 -1 0\n0 -1 -1 -1 0\n0 0 0 0 0\n

//Medium hard
//0 0 -1 0 0\n0 -1 1 -1 0\n-1 1 5 1 -1\n0 -1 1 -1 0\n0 0 -1 0 0\n

//Large hard
//-1 -1 -1 -1 -1\n-1 2 2 2 -1\n-1 2 2 2 -1\n-1 2 2 2 -1\n-1 -1 -1 -1 -1\n