## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)

## -- Set Up doc_source -- ##
# run token in console
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:ba72f793-1507-4c95-bed3-eee1f3723e00"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


## -- Get Raster Data -- ## 
# Step 0: load get raster metadata function
dvk_get_raster_metadata <- function(path, coord_name = NULL, attributeList){
  
  # define a raste object
  raster_obj <- raster::raster(path)
  #message(paste("Reading raster object with proj4string of ", raster::crs(raster_obj)@projargs))
  
  # determine coordinates of raster
  if (is.null(coord_name)){
    coord_name <- raster::crs(raster_obj)@projargs
  }
  
  
  # determine coordinate origins of raster
  if (raster::origin(raster_obj)[1] > 0 & raster::origin(raster_obj)[2] > 0 ){
    # positive x, positive y
    raster_orig <- "Upper Right"
  } else if (raster::origin(raster_obj)[1] < 0 & raster::origin(raster_obj)[2] > 0 ){
    # negative x, positive y
    raster_orig <- "Upper Left"
  } else if (raster::origin(raster_obj)[1] < 0 & raster::origin(raster_obj)[2] < 0 ){
    # negative x, negative y
    raster_orig <- "Lower Left"
  } else if (raster::origin(raster_obj)[1] > 0 & raster::origin(raster_obj)[2] < 0 ){
    # positive x, negative y
    raster_orig <- "Lower Right"
  } else if (raster::origin(raster_obj)[1] == 0 & raster::origin(raster_obj)[2] < 0 ){
    raster_orig <- "Lower Left"
  } else if (raster::origin(raster_obj)[1] == 0 & raster::origin(raster_obj)[2] > 0 ){
    raster_orig <- "Upper Left"
  } else if (raster::origin(raster_obj)[1] > 0 & raster::origin(raster_obj)[2] == 0 ){
    raster_orig <- "Upper Right"
  } else if (raster::origin(raster_obj)[1] < 0 & raster::origin(raster_obj)[2] == 0 ){
    raster_orig <- "Upper Left"
  } else if (identical(raster::origin(raster_obj), c(0,0))){
    raster_orig <- "Upper Left"
  }
  
  raster_info <- list(entityName = basename(path),
                      attributeList = attributeList,
                      spatialReference = list(horizCoordSysName = coord_name),
                      horizontalAccuracy = list(accuracyReport = "unknown"),
                      verticalAccuracy = list(accuracyReport = "unknown"),
                      cellSizeXDirection = raster::res(raster_obj)[1],
                      cellSizeYDirection = raster::res(raster_obj)[2],
                      numberOfBands = raster::nbands(raster_obj),
                      rasterOrigin = raster_orig,
                      rows = dim(raster_obj)[1],
                      columns = dim(raster_obj)[2],
                      verticals = dim(raster_obj)[3],
                      cellGeometry = "pixel")
  return(raster_info)
}


# Step 1: Need the file names
# Create object with file path to folder containing all the tif files
raster_folder <- "Leidman/Leidman-Rasters"

# create list of the file names
raster_names <- list.files(raster_folder, full.names = TRUE)


# Step 2: Find Datum
raster::raster(raster_names[[1]])

# same thing as above but outputs only string with datum
raster::crs(raster::raster(raster_names[[1]]))@projargs

# loop through
for(i in 1:length(raster_names)){
  print(raster::crs(raster::raster(raster_names[[i]]))@projargs)
}
  # all rasters have the same datum WGS84


# create spatial raster object list
spatialRaster <- vector("list", length(raster_names))


# make sure list of raster names matches the order that the entities are
# listed in within the EML doc
names <- vector()
for (i in 1:length(doc$dataset$otherEntity)){
  names[[i]] <- doc$dataset$otherEntity[[i]]$entityName
}

doc$dataset$otherEntity <- doc$dataset$otherEntity[order(names)]
"660_Mosaic_8_7_2019_FPB.tif"


rasters_short <- list.files(raster_folder)
sort.list(list.files(raster_folder))

rasters_short[order(match(rasters_short, order(names)))] 

rasters_short[order(names(rasters_short))]

# this seemed to work: sort(rasters_short) == sort(names)

# entity name "660_DEM_8_11_2019_manual.tif" downloads to "660_DEM_8_12_2019_manual.tif"

# "660_DEM_8_11_2019_manual.tif" // "660_DEM_8_12_2019_FPB.tif" // 
# "660_Mosaic_8_11_2019_FPB.tif"     "660_Mosaic_8_11_2019_manual.tif"







# create spatial raster entities
for(i in 1:length(raster_names)){
  spatialRaster[[i]] <- dvk_get_raster_metadata(raster_names[i],
                                                coord_name = "GCS_WGS_1984",
                                                doc$dataset$otherEntity[[i]]$attributeList) 
}