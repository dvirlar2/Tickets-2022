## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:3c53f9fe-b50d-41a6-8079-6963922138f8"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- mosmet entity retrieval -- ##
{# get indices of mosmet files
  mosmet_index <- which_in_eml(doc$dataset$otherEntity, "entityName", 
                               function(x) {
                                 grepl("mosmet", x) # look for mosseb files
                               })
  
  # get mosmet entities
  mosmet_ent <- doc$dataset$otherEntity[mosmet_index]
}

## -- mosseb entity retrieval -- ##
{# get indices of mosseb files
  mosseb_index <- which_in_eml(doc$dataset$otherEntity, "entityName", 
                               function(x) {
                                 grepl("mosseb", x) # look for mosseb files
                               })
  
  mosseb_ent <- doc$dataset$otherEntity[mosseb_index]
}


## -- assign mosmet attributes -- ##
# read in csv
mosmet_csv <- readr::read_csv("Shupe/MetCity-Level-3/mosmetAtts.csv")

# edit atts in shiny
mosmet_attList <- EML::shiny_attributes(data = NULL, attributes = mosmet_csv)

# assign atts to entity
mosmet_ent[[1]]$attributeList <- EML::set_attributes(attributes = mosmet_attList$attributes)

# define custom units
custom_units <- attList$units 
unitList <- set_unitList(custom_units, as_metadata = TRUE) # updating the unitList
doc$additionalMetadata <- unitList

# generated unique id for each attribute
for(i in 1:length(mosmet_ent[[1]]$attributeList$attribute)){
  mosmet_ent[[1]]$attributeList$attribute[[i]]$id <- UUIDgenerate()
}


# use references
mosmet_ent[[1]]$attributeList$id <- "mosmet_attributes" # use any unique name for your id

for (i in 2:length(mosmet_ent)) {
  mosmet_ent[[i]]$attributeList <- list(references = "mosmet_attributes") # use the id you set above
}

## -- put mosmset entities back to doc -- ##
doc$dataset$otherEntity <- mosmet_ent
eml_validate(doc)
  # TRUE


## -- assign mosseb entities -- ##
# read in csv
mosseb_csv <- readr::read_csv("Shupe/MetCity-Level-3/mossebAtts.csv")

# edit atts in shiny
mosseb_attList <- EML::shiny_attributes(data = NULL, attributes = mosseb_csv)
mosseb_attList <- EML::shiny_attributes(data = NULL, attributes = mosseb_attList$attributes)
mosseb_attList <- EML::shiny_attributes(data = NULL, attributes = mosseb_attList$attributes)
  # forgot to fix qc atts, then forgot about custom units

# assign atts to entity
mosseb_ent[[1]]$attributeList <- EML::set_attributes(attributes = mosseb_attList$attributes)

# define custom units
custom_units_seb <- mosseb_attList$units
unitList_seb <- set_unitList(custom_units_seb, as_metadata = TRUE) # updating the unitList
doc$additionalMetadata <- unitList_seb

# generated unique id for each attribute
for(i in 1:length(mosseb_ent[[1]]$attributeList$attribute)){
  mosseb_ent[[1]]$attributeList$attribute[[i]]$id <- UUIDgenerate()
}

# use references
mosseb_ent[[1]]$attributeList$id <- "mosseb_attributes" # use any unique name for your id

for (i in 2:length(mosseb_ent)) {
  mosseb_ent[[i]]$attributeList <- list(references = "mosseb_attributes") # use the id you set above
}

doc$dataset$otherEntity <- c(mosmet_ent, mosseb_ent)
eml_validate(doc)


## -- update package -- ##
eml_path <- "~/Scratch/Met_City_meteorological_and_surface_flux.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE, 
                                  accessRules = myAccessRules, quiet = FALSE)
