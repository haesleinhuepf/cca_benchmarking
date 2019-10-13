// clij_macro_segmentation.ijm
// ---------------------------
//
// This macro demonstates a workflow consisting of
// * denoising with Gaussian blur
// * background subtraction using the top-hat filter
// * segmentation using thresholding
// * connected components analysis
// 
// Goal is counting nuclei in a 3D dataset showing half a 
// Tribolium embryo imaged in light sheet microscopy
//
// It uses CLIJ for 
//
// Author: Robert Haase, rhaase@mpi-cbg.de
//         September 2019
// -------------------------------------------------------

run("Close All");

// open dataset
open("C:/structure/code/cca_benchmarking/Nantes_000500.tif");

run("32-bit");
getDimensions(width, height, channels, slices, frames);

time = getTime();

// init GPU
run("CLIJ Macro Extensions", "cl_device=");
Ext.CLIJ_clear();

// send input image to the GPU
input = "input";
rename(input);
Ext.CLIJ_push(input);

// crop out a region to spare time by not processing black pixels
cropped = "cropped";
Ext.CLIJ_crop3D(input, cropped, 128, 110, 0, 719, 714, slices - 1);

// denoising
denoised = "denoised";
Ext.CLIJ_blur3D(cropped, denoised, 2, 2, 0);

// top-hat filter to make all nuclei similarily bright and remove background
background = "background";
temp = "temp";
Ext.CLIJ_minimum3DBox(denoised, temp, 15, 15, 0);
Ext.CLIJ_maximum3DBox(temp, background, 15, 15, 0);
background_subtracted = "background_subtracted";
Ext.CLIJ_subtractImages(denoised, background, background_subtracted);

// thresholding to segment nuclei
thresholded = "thresholded";
// TODO: Apply RenyiEntropy thresholding on GPU
Ext.CLIJ_automaticThreshold(background_subtracted, thresholded, "RenyiEntropy");

// connected components analysis to differentiate nuclei from each other
label_map = "label_map";
// TODO: Run connected components analysis on GPU
cca_time = getTime();
Ext.CLIJx_connectedComponentsLabeling(thresholded, label_map);

run("Clear Results");
// TODO: Derive statistics of labelled objects
Ext.CLIJx_statisticsOfLabelledPixels(cropped, label_map);

IJ.log("CLIJ CCA took" + (getTime() - cca_time));

// read out number of objects
Ext.CLIJ_maximumOfAllPixels(label_map);
number_of_objects = getResult("Max", nResults() - 1);



// maximum projection for visualisation
maximum_projected = "maximum_projected";
// TODO: Apply a maximum projection on the GPU
Ext.CLIJ_maximumZProjection(label_map, maximum_projected);

// pull the resulting image from the GPU and show it
Ext.CLIJ_pull(maximum_projected);
run("glasbey on dark");

// measure time and output results
duration = getTime() - time;
print("Number of nuclei: " + number_of_objects);
print("Duration: " + duration + " ms");

