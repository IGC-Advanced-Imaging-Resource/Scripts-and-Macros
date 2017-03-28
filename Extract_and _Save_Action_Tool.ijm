//Macro gets a list of paths to images, even if they are in subdirectories
//Then opens all the images & saves

setBatchMode(true);
dir0=getDirectory("Parent directory of all MM images");
dir0list=newArray();
dir0list=getFileListFullDirectoryTree(dir0,dir0list);

for(j=0; j<dir0list.length; j++){
	print(dir0list[j]);
}

function getFileListFullDirectoryTree(dir,dirListToReturn){
	dirList=getFileList(dir);
	for(i=0;i<dirList.length;i++){
		//print(dirList[i]);
		if(endsWith(dirList[i], ".tif")==true)
		dirListToReturn=appendToArray(dir+dirList[i],dirListToReturn);
		if(File.isDirectory(dir+File.separator+dirList[i])==true)
		dirListToReturn=getFileListFullDirectoryTree(dir+dirList[i],dirListToReturn);
	}
	return dirListToReturn;
}

function appendToArray(value, array) {
temparray=newArray(lengthOf(array)+1);
for(i=0;i<lengthOf(array);i++){
temparray[i]=array[i];
//open(array[i]);
}
temparray[lengthOf(temparray)-1]=value;
array=temparray;
open(array[i]);
return array;
}

//Save option
saveloc = getDirectory("Choose the directory for saving");
count = nImages;

for (i=0; i<count; i++) {
title = getTitle;
saveAs("tiff", saveloc+title);
close;
}
setBatchMode(false);

Dialog.create("Progress");
Dialog.addMessage("Saving Complete!");
Dialog.show;