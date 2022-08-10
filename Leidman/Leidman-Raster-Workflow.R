# Leidman dataset
# Edit file names of mismatched rasters

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

packageId <- "resource_map_urn:uuid:a7fca337-2106-4c2a-a8af-e47fb57b4d1a"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


## -- update DEM system metadata -- ##
# pid for 660_DEM_8_12_2019_manual.tif
pid <- selectMember(dp, "sysmeta@fileName", "660_DEM_8_12_2019_manual.tif")

# load sysmeta
sysmeta <- getSystemMetadata(d1c@mn, pid)

# change file name
sysmeta@fileName <- "660_DEM_8_11_2019_manual.tif"

# update sysmeta
updateSystemMetadata(d1c@mn, pid, sysmeta)
  # TRUE -- filename's been changed


# pid for 660_DEM_8_12_2019_FPB.tif
pid <- selectMember(dp, "sysmeta@fileName", "660_DEM_8_12_2019_FPB.tif")

# load sysmeta
sysmeta <- getSystemMetadata(d1c@mn, pid)

# change file name
sysmeta@fileName <- "660_DEM_8_11_2019_FPB.tif"

# update sysmeta
updateSystemMetadata(d1c@mn, pid, sysmeta)
# TRUE -- filename's been changed


## -- update MOSAiC system metadata -- ##
# pid for 660_Mosaic_8_12_2019_FPB.tif
pid <- selectMember(dp, "sysmeta@fileName", "660_Mosaic_8_12_2019_FPB.tif")

sysmeta <- getSystemMetadata(d1c@mn, pid)

sysmeta@fileName <- "660_Mosaic_8_11_2019_FPB.tif"

updateSystemMetadata(d1c@mn, pid, sysmeta)
  # TRUE -- filename's been changed


# pid for 660_Mosaic_8_12_2019_manual.tif
pid <- selectMember(dp, "sysmeta@fileName", "660_Mosaic_8_12_2019_manual.tif")

sysmeta <- getSystemMetadata(d1c@mn, pid)

sysmeta@fileName <- "660_Mosaic_8_11_2019_manual.tif"

updateSystemMetadata(d1c@mn, pid, sysmeta)
  # TRUE -- filename's been changed


## -- edit entity name -- ##
# Changed the file name for "660_DEM_8_11_2019_FPB.tif" based off of the 
# entity description and conversation with PI. Now need to edit entity name
# to reflect the proper filename
which_in_eml(doc$dataset$otherEntity, "entityName",
             function(x) {grepl("660_DEM_8_12_2019_FPB.tif", x)})
  # 15

doc$dataset$otherEntity[[15]]$entityName <- "660_DEM_8_11_2019_FPB.tif"


## -- change format ids -- ##
pids <- selectMember(dp, "sysmeta@fileName", ".tif")

for(i in 1:length(pids)){
  sysmeta <- getSystemMetadata(d1c@mn, pids[i])
  
  sysmeta@formatId <- "image/geotiff"
  
  updateSystemMetadata(d1c@mn, pids[i], sysmeta)
}

# does updating the package here at this step update the "Data Object Type" of an entity, or no?
# let's test it and find out
  # it does not! so let's update that, and then set the physicals

doc$dataset$otherEntity[[1]]$entityType
  # would changing the entity types automatically change the format IDs? Figure out in test site

for(i in 1:length(doc$dataset$otherEntity)){
  doc$dataset$otherEntity[[i]]$entityType <- "image/geotiff"
}


## -- convert to spatialRasters -- ##
# load function
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
  # should figure out how to add creating a physical to this function

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

# create empty list for spatial raster entities to live
spatialRaster <- vector("list", length(raster_names))


# create spatial raster entities
for(i in 1:length(raster_names)){
  spatialRaster[[i]] <- dvk_get_raster_metadata(raster_names[i],
                                                coord_name = "GCS_WGS_1984",
                                                doc$dataset$otherEntity[[i]]$attributeList) 
}


## -- sanity check -- ##
# make sure all the names of the spatial raster entity match with the names
# of the otherEntity, that way you make sure you didn't miss anything

entity_names <- vector()
spatial_names <- vector()

for (i in 1:length(doc$dataset$otherEntity)){
  entity_names[[i]] <- doc$dataset$otherEntity[[i]]$entityName
  spatial_names[[i]] <- spatialRaster[[i]]$entityName
}

sort(entity_names) == sort(spatial_names)
  # Everything looks good!


## -- add spatialRaster entity -- ##
doc$dataset$spatialRaster <- spatialRaster

doc$dataset$otherEntity <- NULL

eml_validate(doc)
  # Everything still looks good, hooray



## -- set physicals -- ##
# add physicals
for (i in seq_along(doc$dataset$spatialRaster)) {
  raster_name <- doc$dataset$spatialRaster[[i]]$entityName
  
  raster_pid <- selectMember(dp, "sysmeta@fileName", raster_name)
  physical <- arcticdatautils::pid_to_eml_physical(d1c@mn, raster_pid)
  
  doc$dataset$spatialRaster[[i]]$physical <- physical
}

eml_validate(doc)
  # Everything still looks good, hooray


## -- add dataset categorization -- ##
doc <- eml_categorize_dataset(doc, c("Physical Geography", "Hydrology"))


## -- add NSF awards -- ##
doc$dataset$project$funding <- NULL

doc$dataset$project <- NULL

doc$dataset$project <- eml_nsf_to_project("2140003")


eml_award <- eml$award()
eml_award$funderName <- "National Aeronautics and Space Administration Cryosphere Program"
eml_award$awardNumber <- "NNX14AH93G"
eml_award$title <- "Drainage efficiency of the Greenland supraglacial river network"
eml_award$funderIdentifier <- NULL
eml_award$awardUrl <- NULL

doc$dataset$project$award <- c(doc$dataset$project$award, list(eml_award))


## -- remove associated party -- ##
doc$dataset$associatedParty <- NULL


## -- update package -- ##
eml_path <- "~/Scratch/Digital_elevation_models_DEMs_and_ortho_mosaic.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)
