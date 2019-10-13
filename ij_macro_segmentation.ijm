// ij_macro_segmentation.ijm
// -------------------------
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
// Author: Robert Haase, rhaase@mpi-cbg.de
//         September 2019
// -------------------------------------------------------

run("Close All");

// open dataset
open("C:/structure/code/cca_benchmarking/Nantes_000500.tif");

time = getTime();


// crop out a region to spare time by not processing black pixels
makeRectangle(128, 110, 719, 714);
denoised = "denoised";
run("Duplicate...", "title=" + denoised + " duplicate");

// denoising
run("Gaussian Blur...", "sigma=2 stack");

// top-hat filter to make all nuclei similarily bright and remove background
background = "background";
run("Duplicate...", "title=" + background + " duplicate");
//run("Minimum 3D...", "x=15 y=15 z=2");
//run("Maximum 3D...", "x=15 y=15 z=2");
run("Minimum...", "radius=15 stack");
run("Maximum...", "radius=15 stack");
imageCalculator("Subtract create 32-bit stack", denoised, background);

// thresholding to segment nuclei
selectWindow("Result of " + denoised);
setAutoThreshold("RenyiEntropy dark stack");
setOption("BlackBackground", true);
run("Convert to Mask", "method=RenyiEntropy background=Dark black");

// connected components analysis to differentiate nuclei from each other
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
cca_time = getTime();
run("3D Objects Counter", "threshold=128 slice=48 min.=0 max.=101711872 objects");

IJ.log("IJ CCA took" + (getTime() - cca_time));

// maximum projection for visualisation
run("Z Project...", "projection=[Max Intensity]");
run("glasbey on dark");

// read out number of objects
getStatistics(area, mean, min, max, std, histogram);
number_of_objects = max;

// measure time and output results
duration = getTime() - time;
print("Number of nuclei: " + number_of_objects);
print("Duration: " + duration + " ms");

