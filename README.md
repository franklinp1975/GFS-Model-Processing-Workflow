# R Script Documentation: GFS Data Processing Workflow

This documentation provides a guide to the R script designed for processing Global Forecast System (GFS) data from the National Centers for Environmental Prediction (NCEP). The script handles precipitation, maximum temperature (TMAX), minimum temperature (TMIN), and average temperature (TMP) data at a 0.25° resolution, performing tasks such as unzipping, cleaning, resampling, masking, cropping, and saving processed data for specified regions.

## 1. Data Acquisition

The required GFS data products can be downloaded from the NCEP FTP server using an FTP client like FileZilla.

**Tool:** FileZilla [https://filezilla-project.org/]
**Model:** Global Forecast System
**Center:** National Centers for Environmental Prediction (NCEP)

**FileZilla Connection Parameters:**

* **Remote Host:** ftp.cpc.ncep.noaa.gov/
* **Username:** anonymous
* **Password:** anonymous
* **Local site:** `C:\ONCC_GEF\Input\` (or your designated input directory)
* **Remote site:** `/GIS/gfs_0.25`

**Target Products for Download:**

* `gfs_tmp_shp_tif_xxxxx.zip`
* `gfs_tmin_shp_tif_xxxxx.zip`
* `gfs_tmax_shp_tif_xxxxx.zip`
* `gfs_precip_shp_tif_xxxxx.zip`

Place the downloaded `.zip` files into the input directory specified in the script's configuration.

## 2. Script Overview

The R script automates the processing of downloaded GFS data. It performs the following key steps:

* Loading necessary R packages.
* Defining directory configurations.
* Implementing functions for unzipping, cleaning, loading spatial data, and processing rasters.
* Processing pipelines for precipitation, TMAX, TMIN, and TMP data.
* Regional processing and output generation.
* Cleaning up temporary files.

## 3. Script Structure

The script is organized into several sections:

![deepseek_mermaid_20250508_6764fb](https://github.com/user-attachments/assets/5dc895af-1c4a-4192-aed7-f6cac9c6aac6)


### SECTION 1: PACKAGE LOADING

This section loads the required R packages for spatial data manipulation, data handling, and parallel processing.
Required packages include `terra`, `sf`, `dplyr`, `stringr`, `doParallel`, and `foreach`.

### SECTION 2: CONFIGURATION

This section defines the main directories used by the script:
* `main`: The main project directory (`C:/ONCC_GEF` by default).
* `aoi`: Directory for Area of Interest (AOI) geojson files.
* `input`: Directory where downloaded GFS `.zip` files are placed.
* `output`: Directory where processed output files will be saved.
* `pattern`: Path to a template raster file (`pattern_1km.tif`).

**Note:** Update these paths to match your local directory structure.

### SECTION 3: PROCESSING FUNCTIONS

This section contains helper functions:
* `unzip_parallel`: Unzips files in parallel to a specified output folder.
* `clean_directory`: Removes files matching specified patterns from a directory.
* `load_aoi`: Loads AOI geojson files from the specified directory.
* `process_raster`: Resamples and masks a raster using a template and an AOI.
* `deleteFilesAndFolders`: Deletes files and folders within a specified directory (use with caution).
* `process_region`: Crops and masks processed rasters to a specific region and saves the output.

### SECTION 4: DATA PREPARATION

This section loads the template raster and AOI geojson files for Venezuela and specific regions (Cojedes and Guarico by default).

### SECTION 5: DATA PROCESSING PIPELINE FOR RAINFALL

This section processes the precipitation data:
1.  Lists precipitation `.zip` files in the input directory.
2.  Unzips the files using `unzip_parallel`.
3.  Cleans temporary files (dbf, prj, shp, shx, htm) generated during unzipping.
4.  Processes different time intervals (7day, 24h, 48h, etc.) by loading, resampling, and masking rasters.

### SECTION 6: REGIONAL PROCESSING AND OUTPUT FOR RAINFALL

This section processes the processed precipitation rasters for each defined region (Cojedes and Guarico):
1.  Generates output filenames based on region, time interval, and file date.
2.  Crops and masks the rasters to the region's extent using the `process_region` function.
3.  Saves the processed regional rasters as GeoTIFF files in the output directory.

### SECTION 7: CLEANUP FOR RAINFALL

Removes the processed precipitation rasters from memory and performs garbage collection.

### SECTION 8-16: DATA PROCESSING PIPELINES AND REGIONAL PROCESSING FOR TMAX, TMIN, AND TMP

These sections repeat the processing pipeline and regional output steps for TMAX, TMIN, and TMP data, following the same logic as the rainfall processing.

### SECTION 17: CLEAN THE INPUT FOLDER

This section calls the `deleteFilesAndFolders` function to remove all files and folders from the input directory after processing is complete.

**Note:** The line `# deleteFilesAndFolders(dir_config$output) BE CAREFUL. NOT RUN` is commented out for safety. Uncommenting and running this line would delete the processed output files.

Finally, the script cleans the R environment and exits.

## 4. Requirements

* R and RStudio statistical software.
* The required R packages listed in Section 1. Install them if you haven't already using `install.packages()`.
* FileZilla or another FTP client to download the GFS data.
* Sufficient disk space for downloaded and processed files.

## 5. How to Run the Script

1.  Download the target GFS data products from the NCEP FTP server using FileZilla.
2.  Place the downloaded `.zip` files in the directory specified by `dir_config$input`.
3.  Ensure your AOI geojson files are in the directory specified by `dir_config$aoi`.
4.  Ensure your template raster (`pattern_1km.tif`) is in the directory specified by `dir_config$pattern`.
5.  Update the directory paths in SECTION 2 of the script to match your local setup.
6.  Open the R script in an R environment (like RStudio).
7.  Run the script.

The script will process the data and save the regional output files in the directory specified by `dir_config$output`.

## 6. E-learning video

Click on: https://goo.su/vjp9Rp7
