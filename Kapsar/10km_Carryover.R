# Daphne Virlar-Knight
# June 10 2022

# Tasks
# Move over 10km data from original Kapsar dataset into the new split dataset

## -- load libraries -- ##
# general
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- read in source data -- ##
# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

source_packageId <- "resource_map_doi:10.18739/A2P55DJ23"
source_dp  <- getDataPackage(d1c, identifier = source_packageId, lazyLoad=TRUE, quiet=FALSE)

# Get the metadata id
source_xml <- selectMember(source_dp, name = "sysmeta@fileName", value = ".xml")

source_doc <- read_eml(getObject(d1c@mn, source_xml))



## -- read in target data -- ##
target_packageId <- "resource_map_urn:uuid:f5cd17a0-26c7-4c09-aea1-0ff47b960403"
target_dp  <- getDataPackage(d1c, identifier = target_packageId, lazyLoad=TRUE, quiet=FALSE)

# Get the metadata id
target_xml <- selectMember(target_dp, name = "sysmeta@fileName", value = ".xml")

target_doc <- read_eml(getObject(d1c@mn, target_xml))



## -- Copy Over Creator & Awards -- ##
# creator info
target_doc$dataset$creator <- source_doc$dataset$creator

# contact info
target_doc$dataset$contact <- source_doc$dataset$contact

# funding award
target_doc$dataset$project$award <- source_doc$dataset$project$award
target_doc$dataset$project$title <- source_doc$dataset$project$title
target_doc$dataset$project$personnel <- source_doc$dataset$project$personnel 

target_doc$dataset$project$funding <- NULL



## -- add publisher information -- ##
# FAIR
target_doc$dataset$publisher <- source_doc$dataset$publisher



## -- dataset categorization -- ##
target_doc <- eml_categorize_dataset(target_doc, "Human Geography")



# ## -- add entity descriptions -- ##
# for(i in 1:length(target_doc$dataset$otherEntity)){
#   t <- target_doc$dataset$otherEntity[[i]]$entityName
#   t_split <- strsplit(t, split = "_|.tif")
#   
#   # put split string into entity description
#   target_doc$dataset$otherEntity[[i]]$entityDescription <- 
#     paste("Monthly vessel intensity within 1km pixel of coastlines of the study area during", 
#           month.name[as.numeric(t_split[[1]][3])], 
#           t_split[[1]][2])
# }



## -- Copy Over Attribute List -- ##
# Step 1: Find the indices of coastal only entities from the source doc
ten <- which_in_eml(source_doc$dataset$spatialRaster, "entityName", 
                        function(x) {
                          grepl("10km", x)
                        })


# Step 2: Assign only coastal entities to new object
ten <- source_doc$dataset$spatialRaster[ten]


# Step 3: **DOUBLE CHECK** that entities in source and target doc are in same order
ten[[1]]$entityName
target_doc$dataset$otherEntity[[1]]$entityName
# entities are not in the same order. use order[names] to put target_doc in order


# Step 4: Put target_doc in order
names <- vector()
for (i in 1:length(target_doc$dataset$otherEntity)){
  names[[i]] <- target_doc$dataset$otherEntity[[i]]$entityName
}

target_doc$dataset$otherEntity <- target_doc$dataset$otherEntity[order(names)]


# Step 5: check entity orders
ten[[1]]$entityName
target_doc$dataset$otherEntity[[1]]$entityName

# need to reverse ten
ten <- rev(ten)


# Step 6: Copy over the attributes
for (i in 1:length(target_doc$dataset$otherEntity)){ 
  target_doc$dataset$otherEntity[[i]]$attributeList <- ten[[i]]$attributeList
}


eml_validate(target_doc)
# TRUE



## -- Load in Other Entity to Raster Function -- ##
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



## -- Create Coastal SpatialRasters -- ##
# Step 1: Need the file names
# Create object with file path to folder containing all the tif files
ten_folder <- "Kapsar/10km"

# create list of the file names
ten_filenames <- list.files(ten_folder, full.names = TRUE)



# Step 2: Create spatialRaster
# Create empty vector length of coastal_names.
# We're going to use this to iterate through
spatialRaster <- vector("list", length(ten_filenames))

# create spatial raster entities
for(i in 1:length(ten_filenames)){
  spatialRaster[[i]] <- dvk_get_raster_metadata(ten_filenames[i],
                                                coord_name = "GCS_North_American_1983",
                                                target_doc$dataset$otherEntity[[i]]$attributeList) 
}



# Step 3: Add spatialRaster to Doc
target_doc$dataset$spatialRaster <- spatialRaster

# null other entity, otherwise there will be validation problems
target_doc$dataset$otherEntity <- NULL

eml_validate(target_doc)
# TRUE



## -- update package -- ##
eml_path <- "~/Scratch/North_Pacific_and_Arctic_Marine_Vessel_Traffic_10km.xml"
write_eml(target_doc, eml_path)

dp <- replaceMember(target_dp, target_xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)

## -- add PI access -- ##
# Manually set ORCiD
# kelly Kapsar
subject <- 'http://orcid.org/0000-0002-2048-5020'

pids <- arcticdatautils::get_package(d1c@mn, target_packageId)

set_rights_and_access(d1c@mn,
                      pids = c(target_xml, pids$data, target_packageId),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))


# ---------------------------------------------------------------------------- #


## -- add physicals -- ##
all_pids <- get_package(d1c@mn, target_packageId, file_names = TRUE)
all_pids <- reorder_pids(all_pids$data, target_doc)

# for loop to assign physicals for each file 
for (i in 1:length(all_pids)){
  target_doc$dataset$spatialRaster[[i]]$physical <- pid_to_eml_physical(d1c@mn, all_pids[[i]])
}


## -- Fix FormatIds -- ##
for(i in 1:length(target_doc$dataset$spatialRaster)){
  target_doc$dataset$spatialRaster[[i]]$physical$dataFormat$externallyDefinedFormat$formatName <- "image/geotiff"
}



## -- Assign Funding -- ##
# remove funding section
target_doc$dataset$project$funding <- NULL


eml_award <- eml$award()
eml_award$funderName <- "United States Fish & Wildlife Service"
eml_award$awardNumber <- "F20AC10873-00"
eml_award$title <- "North Pacific and Arctic Marine Vessel Traffic Dataset (2015-2020)"
eml_award$funderIdentifier <- NULL
eml_award$awardUrl <- NULL

target_doc$dataset$project$award <- NULL
target_doc$dataset$project$award <- eml_award
eml_validate(target_doc)



## -- update package -- ##
eml_path <- "~/Scratch/North_Pacific_and_Arctic_Marine_Vessel_Traffic_10km.xml"
write_eml(target_doc, eml_path)

dp <- replaceMember(target_dp, target_xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)

## -- add PI access -- ##
# Manually set ORCiD
# kelly Kapsar
subject <- 'http://orcid.org/0000-0002-2048-5020'

pids <- arcticdatautils::get_package(d1c@mn, "resource_map_urn:uuid:63ac2c04-6238-4a4e-ba83-b05c2f9484b0")

set_rights_and_access(d1c@mn,
                      pids = c(pids$metadata, pids$data, pids$resource_map),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))


# ---------------------------------------------------------------------------- #
# update system metadata formatIds for all rasters


# get data pids for most recent packageId
pids <- arcticdatautils::get_package(d1c@mn, target_packageId)


sysmeta <- list()

for(i in 1:length(pids$data)){
  # get system metadata for all pids
  sysmeta[[i]] <- getSystemMetadata(d1c@mn, pids$data[[i]])
  
  # change format id for all pids
  sysmeta[[i]]@formatId <- "image/geotiff"
  
  # update system metadata
  updateSystemMetadata(d1c@mn, pids$data[[i]], sysmeta[[i]])
}




## -- fix title -- ## 
target_doc$dataset$title <- "North Pacific and Arctic Marine Vessel Traffic Dataset (2015-2020); 10 Kilometer Resolution."


## -- fix entity names -- ##
library(stringr)

for(i in 1:length(target_doc$dataset$spatialRaster)){
  target_doc$dataset$spatialRaster[[i]]$entityName <- 
    str_replace_all(target_doc$dataset$spatialRaster[[i]]$entityName, "-", "_")
}





