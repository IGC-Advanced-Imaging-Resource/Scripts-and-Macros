// Macro asks for a folder of input images and folder to save them in
// Splits the channels of the images (expects 3) and saves the channels separately

setBatchMode(true);
dir=getDirectory("Choose a Directory"); 
print(dir); 
list = getFileList(dir); 
saveloc = getDirectory("Choose the directory for saving");

for (i=0; i<list.length; i++) { 
     if (endsWith(list[i], ".tif")){ 
               print(i + ": " + dir+list[i]); 
             open(dir+list[i]); 
             imgName=getTitle(); 
         baseNameEnd=indexOf(imgName, ".tif"); 
         baseName=substring(imgName, 0, baseNameEnd);
         run("Split Channels"); 
         selectWindow("C1-"+imgName); 
         saveAs("Tiff", saveloc + "C1-"+baseName); 
         close(); 
         selectWindow("C2-"+imgName); 
         saveAs("Tiff", saveloc + "C2-"+baseName); 
         close(); 
         selectWindow("C3-"+imgName); 
         saveAs("Tiff", saveloc + "C3-"+baseName); 
         close(); 
         run("Close All"); 
     } else {
      }
} 


setBatchMode(false);

Dialog.create("Progress");
Dialog.addMessage("Saving Complete!");
Dialog.show;
