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

packageId <- "resource_map_urn:uuid:caddc5b2-1bb5-4e44-95d7-881f2b040044"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))



## -- create spatial vector -- ##
# step 1: read in shapefile
shp_pid <- selectMember(dp, "sysmeta@fileName", "AK_Boat_Survey_June_2022c.zip")

shapefile <- arcticdatautils::read_zip_shapefile(d1c@mn, shp_pid)


# step 2: get coordinate system
  # Take the Datum and add GCS (Geographic Coordinate System) in front
sf::st_crs(shapefile)
  # DATUM["North American Datum 1983"


# step 3: find geometry of shapefile
sf::st_geometry(shapefile)
  # tells me that geometry type is LINESTRING, but based off the attributes I
  # know that's not the full picture. 

sf::st_geometry_type(shapefile)
  # Tells me there are 18 levels, and many different geometries. 
  # Therefore, I know I should use "MultiGeometry" for the geometry of the
  # spatial vector I'm going to create


# step 4: create spatial vector entity
spatialVector <- pid_to_eml_entity(d1c@mn, 
                                   shp_pid, 
                                   entity_type = "spatialVector",
                                   entityName = "AK_Boat_Survey_June_2022c.zip",
                                   entityDescription = "Spatial vector description",
                                   attributeList = doc$dataset$spatialVector[[1]]$attributeList,
                                   geometry = "MultiGeometry",
                                   spatialReference = list(horizCoordSysName = "GCS_North_American_1983"))

# step 5: add spatial vector to doc
doc$dataset$spatialVector[[1]] <- spatialVector
doc$dataset$otherEntity[[2]] <- NULL
eml_validate(doc)


## -- edit format ID -- ##
# Since the spatial vector formula creates a physical based off of this,
# should probably make changing the format id a higher step on the to-do list.
# That way you don't have to edit the format id AND physical :facepalm:

# format id
vector_pid <- selectMember(dp, "sysmeta@fileName", ".zip")
sysmeta <- getSystemMetadata(d1c@mn, vector_pid)
sysmeta@formatId <- "application/vnd.shp+zip"
  
updateSystemMetadata(d1c@mn, vector_pid, sysmeta)


# physical format name
doc$dataset$spatialVector$physical$dataFormat$externallyDefinedFormat$formatName <- "application/vnd.shp+zip"

eml_validate(doc)


## -- add FAIR -- ##
doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)



## -- update package -- ##
eml_path <- "~/Scratch/Geospatial_data_about_watercraft_movements_in_Alaska.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)


