## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)

## -- general setup -- ##
# run token in console
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

# Get the package
packageId <- "resource_map_urn:uuid:900511c9-b066-4d42-b47a-157bf8b8d376"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

# Get the metadata id
xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- get previous version -- ##
# get all versions of metadata
get_all_versions(d1c@mn, xml)
  # I know which one one I'm looking for: 13

# Read in the old metadata
old_doc <- read_eml(getObject(d1c@mn, "urn:uuid:e5a3641c-04b9-4fc3-9fb5-1a57c00f7a12"))


## -- re-do spatial raster -- ## 
# load raster
tiff <- "~/Tickets-2022/Polashenski/athabasca_landsat8_velocity_20180820to20190702_metersPerDay.tif"


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
  # does this function somehow retain the entity decription?

# run function
spatialRaster <- dvk_get_raster_metadata(tiff, "GCS_WGS_1984", old_doc$dataset$otherEntity$attributeList)


# overwrite current spatial raster entity
doc$dataset$spatialRaster <- spatialRaster

# add entity description
doc$dataset$spatialRaster$entityDescription <- doc$dataset$otherEntity$entityDescription

# get rid of other entity
doc$dataset$otherEntity <- NULL

eml_validate(doc)
  # TRUE


## -- update package -- ##
eml_path <- "~/Scratch/Declining_basal_motion_drives_the_long_term.xml"
write_eml(doc, eml_path)

# replace eml 
dp <- replaceMember(dp, xml, replacement = eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)
