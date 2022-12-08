# GOAL: Need to add annotations to depth attribute for .tifs, and 
#       need to add annotatios to .gpkg attributes
#       need to change ratio to interval for lat, lon, temp

## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:9cc3f9ce-db08-4ffa-9683-74529d42f1f6"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- add .tif annotations -- ##
# set property URI
depth_property <- list(label = "contains measurements of type", 
                       propertyURI = "http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#containsMeasurementsOfType")


# set value URI
depth_value <- list(label = "depth", 
                    valueURI = "http://purl.dataone.org/odo/ECSO_00000515")


# assign annotation to rasters
for(i in seq_along(doc$dataset$spatialRaster)){
 doc$dataset$spatialRaster[[i]]$attributeList$attribute$annotation$propertyURI <- depth_property
 
 doc$dataset$spatialRaster[[i]]$attributeList$attribute$annotation$valueURI <- depth_value
}


eml_validate(doc)
  # TRUE


## -- change ratio to interval -- ##
# set interval for coordinates
interval <- list()
interval$unit$standardUnit <- "degree"
interval$numericDomain$numberType <- "real"

# set for all lat/lon attributes

for (i in seq_along(doc$dataset$spatialVector)){
  for (j in seq_along(doc$dataset$spatialVector[[i]]$attributeList$attribute)){
    if (grepl('lat', doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$attributeName)){
      # null ratio
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$measurementScale$ratio <- NULL
      
      # add interval
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$measurementScale$interval <- interval
      
    } else if (grepl('lon', doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$attributeName)){
      # null ratio
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$measurementScale$ratio <- NULL
      
      # add interval
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$measurementScale$interval <- interval
      
    } else if(grepl('tempC', doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$attributeName)){
      # null ratio
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$measurementScale$ratio <- NULL
      
      # add interval
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$measurementScale$interval <- interval
      
      # change unit
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$measurementScale$interval$unit$standardUnit <- "celsius"
    }
  }
}

eml_validate(doc)
  # TRUE


## -- create annotations -- ##
# depth
depth <- list()

# set property URI
depth$propertyURI <- list(label = "contains measurements of type", 
                       propertyURI = "http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#containsMeasurementsOfType")

# set value URI
depth$valueURI <- list(label = "depth", 
                    valueURI = "http://purl.dataone.org/odo/ECSO_00000515")


# time
time <- list()
time$propertyURI <- depth$propertyURI
time$valueURI <- list(label = "time of measurement", 
                      valueURI = "http://purl.dataone.org/odo/ECSO_00002040")


# lat
lat <- list()
lat$propertyURI <- depth$propertyURI
lat$valueURI <- list(label = "latitude coordinate", 
                     valueURI = "http://purl.dataone.org/odo/ECSO_00002130")

# lon
lon <- list()
lon$propertyURI <- depth$propertyURI
lon$valueURI <- list(label = "longitude coordinate", 
                     valueURI = "http://purl.dataone.org/odo/ECSO_00002132")

# temp
temp <- list()
temp$propertyURI <- depth$propertyURI
temp$valueURI <- list(label = "Temperature Measurement Type", 
                      valueURI = "http://purl.dataone.org/odo/ECSO_00001104")



## -- add vector annotations -- ##
for (i in seq_along(doc$dataset$spatialVector)){
  for (j in seq_along(doc$dataset$spatialVector[[i]]$attributeList$attribute)){
    if (grepl('lat', doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$attributeName)){
      # add lat annotation
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$annotation <- lat
      
    } else if (grepl('lon', doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$attributeName)){
      # add lon annotation
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$annotation <- lon
      
    } else if (grepl('depth', doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$attributeName)){
      # add depth annotation 
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$annotation <- depth
      
    } else if (grepl('timeStamp', doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$attributeName)){
      # add time annotation
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$annotation <- time
      
    } else if (grepl('tempC', doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$attributeName)){
      # add temp annotation
      doc$dataset$spatialVector[[i]]$attributeList$attribute[[j]]$annotation <- temp
    }
  }
}

eml_validate(doc)
  # TRUE


## -- update package -- ##
eml_path <- "~/Scratch/Beaver_pond_bathymetry_rasters_and_point_depths.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE, 
                                  accessRules = myAccessRules, quiet = FALSE)