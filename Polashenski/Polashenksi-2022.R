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
packageId <- "resource_map_urn:uuid:e5a3641c-04b9-4fc3-9fb5-1a57c00f7a12"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

# Get the metadata id
xml <- selectMember(dp, "sysmeta@fileName", ".xml")

# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))


## -- edit attribute tables -- ##
# Goal 1: change lat/long from ratio to interval
# Goal 2: create custom unit "meterPerYear" 

# Data Table 1
atts <- get_attributes(doc$dataset$dataTable[[1]]$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)

doc$dataset$dataTable[[1]]$attributeList <- set_attributes(atts_edited$attributes)

custom_units <- atts_edited$units
unitList <- set_unitList(custom_units, as_metadata = TRUE)
doc$additionalMetadata <- unitList

eml_validate(doc)
  #TRUE


# Data Table 2
atts <- get_attributes(doc$dataset$dataTable[[2]]$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)

doc$dataset$dataTable[[2]]$attributeList <- set_attributes(atts_edited$attributes)
  # because I kept the meterPerYear info completely the same, I only need to 
  # add it to the additional metadata once


# Data Table 3
atts <- get_attributes(doc$dataset$dataTable[[3]]$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)

doc$dataset$dataTable[[3]]$attributeList <- set_attributes(atts_edited$attributes)


# Data Table 4
atts <- get_attributes(doc$dataset$dataTable[[4]]$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)

doc$dataset$dataTable[[4]]$attributeList <- set_attributes(atts_edited$attributes)


## -- convert other entities to spatial raster  -- ##
# set path
tiff <- "~/Tickets-2022/Polashenski/polashenski.tif"

# find coordinate system
rgdal::GDALinfo(tiff)
  # projection  +proj=utm +zone=11 +datum=WGS84 +units=m +no_defs 

raster::raster(tiff)
  # crs: +proj=utm +zone=11 +datum=WGS84 +units=m +no_defs 


spatialRaster <- dvk_get_raster_metadata(tiff, "GCS_WGS_1984", doc$dataset$otherEntity$attributeList)

doc$dataset$spatialRaster <- spatialRaster
doc$dataset$otherEntity <- NULL

eml_validate(doc)


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
