# Script to process 0.25° GFS precipitation data
# Model: Global Forecast System (NCEP)
# Optimized version: v1.0
#///////////////////////////////////////////////////////////////////////////////

# SECTION 1: PACKAGE LOADING ----
#///////////////////////////////////////////////////////////////////////////////
required_packages <- c("terra", "sf", "dplyr", "stringr", "doParallel", "foreach")
invisible(lapply(required_packages, library, character.only = TRUE))

# SECTION 2: CONFIGURATION ----
#///////////////////////////////////////////////////////////////////////////////
# Define main directories
dir_config <- list(
  main = normalizePath("C:/ONCC_GEF"),
  aoi = file.path("C:/ONCC_GEF", "AOI"),
  input = file.path("C:/ONCC_GEF", "Input"),
  output = file.path("C:/ONCC_GEF", "Outcome"),
  pattern = file.path("C:/ONCC_GEF", "Pattern", "pattern_1km.tif")
)

# SECTION 3: PROCESSING FUNCTIONS ----
#///////////////////////////////////////////////////////////////////////////////
# Function to unzip files in parallel
unzip_parallel <- function(file_paths, output_folder) {
  cl <- makeCluster(max(1, detectCores() - 4))
  registerDoParallel(cl)
  
  foreach(file = file_paths, .packages = "utils") %dopar% {
    unzip(file, exdir = output_folder)
    file.path(output_folder, basename(file))
  }
  
  stopCluster(cl)
}

# Function to clean up temporary files
clean_directory <- function(path, patterns) {
  list.files(path, pattern = paste(patterns, collapse = "|"), 
             full.names = TRUE) |> 
    file.remove()
}

# Function to load AOI shapefiles
load_aoi <- function(pattern, dir_path = dir_config$aoi) {
  list.files(dir_path, pattern, full.names = TRUE) |> 
    st_read(quiet = TRUE) |> 
    vect()
}

# Function to process raster files
process_raster <- function(file_path, template, aoi) {
  rast(file_path) |> 
    resample(template, method = "bilinear") |> 
    mask(aoi)
}

# Function to delete files and folders
deleteFilesAndFolders <- function(folder) {
  # Check if the folder exists
  if (!dir.exists(folder)) {
    stop("Folder does not exist")
  }
  
  # Get all items in the folder (both files and directories)
  all_items <- list.files(folder, full.names = TRUE)
  
  # Identify which items are directories
  is_directory <- dir.exists(all_items)
  
  # Separate files and directories
  files <- all_items[!is_directory]
  directories <- all_items[is_directory]
  
  # Delete files first
  if (length(files) > 0) {
    file.remove(files)
  }
  
  # Delete directories (including their contents)
  if (length(directories) > 0) {
    unlink(directories, recursive = TRUE)
  }
  
  # Return confirmation message
  paste("All files and folders in", folder, "have been deleted")
}

# SECTION 4: DATA PREPARATION ----
#///////////////////////////////////////////////////////////////////////////////
# Load spatial data
template_raster <- rast(dir_config$pattern)
venezuela_aoi <- load_aoi("Venezuela")
regions <- list(
  Cojedes = load_aoi("Cojedes"),
  Guarico = load_aoi("Guarico")
)

# SECTION 5: DATA PROCESSING PIPELINE FOR RAINFALL ----
#///////////////////////////////////////////////////////////////////////////////
# Process precipitation data
gfs_files <- list.files(dir_config$input, "gfs_precip", full.names = TRUE)
unzip_parallel(gfs_files, dir_config$input)

# Clean temporary files
gfs_precipitation_path <- list.files(path = dir_config$input,
	pattern = "gfs_precip",
	full.names = TRUE)

rainfall_folder <- gfs_precipitation_path[1]

clean_directory(rainfall_folder, c("\\.dbf$", "\\.prj$", "\\.shp$", 
                                   "\\.shx$", "\\.htm$"))

# Process time intervals
time_intervals <- c("7day", "24", "48", "72", "96", "120", "144", "168")
processed_rasters <- lapply(time_intervals, function(t) {
  list.files(rainfall_folder, 
            pattern = ifelse(t == "7day", t, paste0("_", t, "_")),
            full.names = TRUE) |> 
    process_raster(template_raster, venezuela_aoi)
}) |> setNames(paste0("data_", time_intervals, "h"))

# SECTION 6: REGIONAL PROCESSING AND OUTPUT FOR RAINFALL ----
#///////////////////////////////////////////////////////////////////////////////
# Generate output filenames
file_date <- str_extract(basename(gfs_files[1]), "\\d{8}")

process_region <- function(region_name, aoi) {
  lapply(names(processed_rasters), function(t) {
    cropped <- crop(processed_rasters[[t]], ext(aoi)) |> mask(aoi)
    
    fname <- sprintf("%s_%s_precip_%s.tif",
                    tolower(region_name),
                    str_remove(t, "data_"),
                    file_date)
    
    writeRaster(cropped, file.path(dir_config$output, fname), 
                overwrite = TRUE)
    return(fname)
  })
}

# Process all regions
mapply(process_region, names(regions), regions, SIMPLIFY = FALSE)

# SECTION 7: CLEANUP FOR RAINFALL ----
#///////////////////////////////////////////////////////////////////////////////
rm(processed_rasters)
gc()

# SECTION 8: DATA PROCESSING PIPELINE FOR TMAX ----
#///////////////////////////////////////////////////////////////////////////////
# Process TMAX data
gfs_files <- list.files(dir_config$input, "gfs_tmax", full.names = TRUE)
unzip_parallel(gfs_files, dir_config$input)

# Clean temporary files
gfs_tmax_path <- list.files(path = dir_config$input,
	pattern = "gfs_tmax",
	full.names = TRUE)

tmax_folder <- gfs_tmax_path[1]

clean_directory(tmax_folder, c("\\.dbf$", "\\.prj$", "\\.shp$", 
                                   "\\.shx$", "\\.htm$"))

# Process time intervals
time_intervals <- c("7day", "24", "48", "72", "96", "120", "144", "168")
processed_rasters <- lapply(time_intervals, function(t) {
  list.files(tmax_folder, 
            pattern = ifelse(t == "7day", t, paste0("_", t, "_")),
            full.names = TRUE) |> 
    process_raster(template_raster, venezuela_aoi)
}) |> setNames(paste0("data_", time_intervals, "h"))

# SECTION 9: REGIONAL PROCESSING AND OUTPUT FOR TMAX ----
#///////////////////////////////////////////////////////////////////////////////
# Generate output filenames
file_date <- str_extract(basename(gfs_files[1]), "\\d{8}")

process_region <- function(region_name, aoi) {
  lapply(names(processed_rasters), function(t) {
    cropped <- crop(processed_rasters[[t]], ext(aoi)) |> mask(aoi)
    
    fname <- sprintf("%s_%s_tmax_%s.tif",
                    tolower(region_name),
                    str_remove(t, "data_"),
                    file_date)
    
    writeRaster(cropped, file.path(dir_config$output, fname), 
                overwrite = TRUE)
    return(fname)
  })
}

# Process all regions
mapply(process_region, names(regions), regions, SIMPLIFY = FALSE)

# SECTION 10: CLEANUP FOR TMAX ----
#///////////////////////////////////////////////////////////////////////////////
rm(processed_rasters)
gc()

# SECTION 11: DATA PROCESSING PIPELINE FOR TMIN ----
#///////////////////////////////////////////////////////////////////////////////
# Process TMIN data
gfs_files <- list.files(dir_config$input, "gfs_tmin", full.names = TRUE)
unzip_parallel(gfs_files, dir_config$input)

# Clean temporary files
gfs_tmin_path <- list.files(path = dir_config$input,
	pattern = "gfs_tmin",
	full.names = TRUE)

tmin_folder <- gfs_tmin_path[1]

clean_directory(tmin_folder, c("\\.dbf$", "\\.prj$", "\\.shp$", 
                                   "\\.shx$", "\\.htm$"))

# Process time intervals
time_intervals <- c("7day", "24", "48", "72", "96", "120", "144", "168")
processed_rasters <- lapply(time_intervals, function(t) {
  list.files(tmin_folder, 
            pattern = ifelse(t == "7day", t, paste0("_", t, "_")),
            full.names = TRUE) |> 
    process_raster(template_raster, venezuela_aoi)
}) |> setNames(paste0("data_", time_intervals, "h"))

# SECTION 12: REGIONAL PROCESSING AND OUTPUT FOR TMIN ----
#///////////////////////////////////////////////////////////////////////////////
# Generate output filenames
file_date <- str_extract(basename(gfs_files[1]), "\\d{8}")

process_region <- function(region_name, aoi) {
  lapply(names(processed_rasters), function(t) {
    cropped <- crop(processed_rasters[[t]], ext(aoi)) |> mask(aoi)
    
    fname <- sprintf("%s_%s_tmin_%s.tif",
                    tolower(region_name),
                    str_remove(t, "data_"),
                    file_date)
    
    writeRaster(cropped, file.path(dir_config$output, fname), 
                overwrite = TRUE)
    return(fname)
  })
}

# Process all regions
mapply(process_region, names(regions), regions, SIMPLIFY = FALSE)

# SECTION 13: CLEANUP FOR TMIN ----
#///////////////////////////////////////////////////////////////////////////////
rm(processed_rasters)
gc()

# SECTION 14: DATA PROCESSING PIPELINE FOR TMP ----
#///////////////////////////////////////////////////////////////////////////////
# Process TMP data
gfs_files <- list.files(dir_config$input, "gfs_tmp", full.names = TRUE)
unzip_parallel(gfs_files, dir_config$input)

# Clean temporary files
gfs_tmp_path <- list.files(path = dir_config$input,
	pattern = "gfs_tmp",
	full.names = TRUE)

tmp_folder <- gfs_tmp_path[1]

clean_directory(tmp_folder, c("\\.dbf$", "\\.prj$", "\\.shp$", 
                                   "\\.shx$", "\\.htm$"))

# Process time intervals
time_intervals <- c("7day", "24", "48", "72", "96", "120", "144", "168")
processed_rasters <- lapply(time_intervals, function(t) {
  list.files(tmp_folder, 
            pattern = ifelse(t == "7day", t, paste0("_", t, "_")),
            full.names = TRUE) |> 
    process_raster(template_raster, venezuela_aoi)
}) |> setNames(paste0("data_", time_intervals, "h"))

# SECTION 15: REGIONAL PROCESSING AND OUTPUT FOR TMP ----
#///////////////////////////////////////////////////////////////////////////////
# Generate output filenames
file_date <- str_extract(basename(gfs_files[1]), "\\d{8}")

process_region <- function(region_name, aoi) {
  lapply(names(processed_rasters), function(t) {
    cropped <- crop(processed_rasters[[t]], ext(aoi)) |> mask(aoi)
    
    fname <- sprintf("%s_%s_tmp_%s.tif",
                    tolower(region_name),
                    str_remove(t, "data_"),
                    file_date)
    
    writeRaster(cropped, file.path(dir_config$output, fname), 
                overwrite = TRUE)
    return(fname)
  })
}

# Process all regions
mapply(process_region, names(regions), regions, SIMPLIFY = FALSE)

# SECTION 16: CLEANUP FOR TMP ----
#///////////////////////////////////////////////////////////////////////////////
rm(processed_rasters)
gc()

# SECTION 17: CLEAN THE INPUT FOLDER ----
deleteFilesAndFolders(dir_config$input)
# deleteFilesAndFolders(dir_config$output) BE CAREFUL. NOT RUN
#///////////////////////////////////////////////////////////////////////////////
# End of script
rm(list = ls(all.names = TRUE, envir = .GlobalEnv))  # Clear all objects including hidden
invisible(gc())  # Force garbage collection
cat("\f")  # More universal form feed character
# Close all open connections
quit(save = "no", status = 0)
