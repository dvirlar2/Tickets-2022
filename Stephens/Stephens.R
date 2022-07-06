## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:10df07bc-d062-4bfa-9bca-60a900a2b40e"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- fix missing value codes -- ##
# need to add a closing paranthesis

# DATA TABLE 1
length(doc$dataset$dataTable[[1]]$attributeList$attribute)

doc$dataset$dataTable[[1]]$attributeList$attribute[[10]]$missingValueCode$codeExplanation <- 
  "Some samples were not able to be analyzed due to the length of time since sample collection (radioactive decay had reduced the activities to below detection limits)."

doc$dataset$dataTable[[1]]$attributeList$attribute[[11]]$missingValueCode$codeExplanation <- 
  "Some samples were not able to be analyzed due to the length of time since sample collection (radioactive decay had reduced the activities to below detection limits)."


# DATA TABLE 3
length(doc$dataset$dataTable[[3]]$attributeList$attribute)

for(i in c(7,8,11,12)){
  doc$dataset$dataTable[[3]]$attributeList$attribute[[i]]$missingValueCode$codeExplanation <- 
    "Some samples were not able to be analyzed due to the length of time since sample collection (radioactive decay had reduced the activities to below detection limits)."
}


# DATA TABLE 4
for(i in c(8:10, 12:13)){
  doc$dataset$dataTable[[4]]$attributeList$attribute[[i]]$missingValueCode$codeExplanation <- 
    "Some samples were not able to be analyzed due to the length of time since sample collection (radioactive decay had reduced the activities to below detection limits)."
}



## -- fix lat/long measurement types -- ##

# make sure to save annotations, because they'll get overwritten by the shiny app
aerosols <- doc$dataset$dataTable[[1]]$attributeList$attribute
seawater <- doc$dataset$dataTable[[2]]$attributeList$attribute
icecores <- doc$dataset$dataTable[[3]]$attributeList$attribute
snow <- doc$dataset$dataTable[[4]]$attributeList$attribute


# make sure to save additional metadata?
add_meta <- doc$additionalMetadata


# aerosols
atts <- get_attributes(doc$dataset$dataTable[[1]]$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)
doc$dataset$dataTable[[1]]$attributeList <- set_attributes(atts_edited$attributes)

for(i in 5:8){
doc$dataset$dataTable[[1]]$attributeList$attribute[[i]]$annotation <- 
  aerosols[[i]]$annotation
}

eml_validate(doc)
  # TRUE

# seawater
atts <- get_attributes(doc$dataset$dataTable[[2]]$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)
doc$dataset$dataTable[[2]]$attributeList <- set_attributes(atts_edited$attributes)

for(i in 4:5){
  doc$dataset$dataTable[[2]]$attributeList$attribute[[i]]$annotation <- 
    seawater[[i]]$annotation
}

doc$dataset$dataTable[[2]]$attributeList$attribute[[7]]$measurementScale$ratio$unit$customUnit <- 
  "becquerelPerMeterCubed"

doc$dataset$dataTable[[2]]$attributeList$attribute[[8]]$measurementScale$ratio$unit$customUnit <- 
  "becquerelPerMeterCubed"


eml_validate(doc)
  # TRUE


# icecores
atts <- get_attributes(doc$dataset$dataTable[[3]]$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)
doc$dataset$dataTable[[3]]$attributeList <- set_attributes(atts_edited$attributes)

for(i in 5:6){
  doc$dataset$dataTable[[3]]$attributeList$attribute[[i]]$annotation <- 
    icecores[[i]]$annotation
}

doc$dataset$dataTable[[3]]$attributeList$attribute[[11]]$measurementScale$ratio$unit$customUnit <- 
  "becquerelPerMeterCubed"

doc$dataset$dataTable[[3]]$attributeList$attribute[[12]]$measurementScale$ratio$unit$customUnit <- 
  "becquerelPerMeterCubed"

eml_validate(doc)


# snow
atts <- get_attributes(doc$dataset$dataTable[[4]]$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)
doc$dataset$dataTable[[4]]$attributeList <- set_attributes(atts_edited$attributes)

for(i in 6:7){
  doc$dataset$dataTable[[4]]$attributeList$attribute[[i]]$annotation <- 
    snow[[i]]$annotation
}


doc$dataset$dataTable[[4]]$attributeList$attribute[[12]]$measurementScale$ratio$unit$customUnit <- 
  "becquerelPerMeterCubed"

doc$dataset$dataTable[[4]]$attributeList$attribute[[13]]$measurementScale$ratio$unit$customUnit <- 
  "becquerelPerMeterCubed"

eml_validate(doc)
  # TRUE 


## -- edit abstract -- ##
# define R/V as research vessel 

doc$dataset$abstract$para <- "The Multidisciplinary drifting Observatory for the Study of Arctic Climate (MOSAiC) expedition was an international initiative in which research vessel (R/V) Polarstern drifted with the sea ice in the Central Arctic Ocean from October 2019 to September 2020. Here, we present data from a study in which Beryllium-7, a naturally occurring radioactive isotope with a half-life of 53 days, is used as a tracer for the atmospheric deposition of trace elements to the ocean / ice surface and their partitioning among the seawater, ice and snow catchments during winter and spring. The data sets include measurements of Be-7 in 1) aerosol particles collected on filters using a high volume sampler on Polastern, 2) seawater from the upper water column (8-60 meters depth) collected using the ship’s seawater intake system and using pumps on the ice floe, and 3) ice cores, snow, and frost flowers collected from sites on the MOSAiC and surrounding ice floes. Be-7 analysis was performed using high purity germanium gamma detectors."


## -- edit methods -- ##
# define keV

doc$dataset$methods$methodStep[[2]]$description$para <- "Be-7 has a readily identifiable gamma peak at 478 keV (kiloelectron volt). The raw counts are corrected for background signal, and the resultant activity is corrected to the time of collection using the decay constant."


eml_validate(doc)


# -- update the package -- ##
# write EML
eml_path <- "~/Scratch/Beryllium_7_concentrations_in_aerosols_seawater_.xml"
write_eml(doc, eml_path)



# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)




## -------------------------------------------------------------------------- ##

# load newest version
packageId <- "resource_map_urn:uuid:245a6617-f3d8-4b5a-8198-b7d37ac7c3ef"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)
xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


# load the version immediately before
doc2 <- read_eml(getObject(d1c@mn, "urn:uuid:3665714c-40bb-4570-a71a-452ef52f430c"))



# Load back annotations from previous version
aerosols <- doc2$dataset$dataTable[[1]]$attributeList$attribute
seawater <- doc2$dataset$dataTable[[2]]$attributeList$attribute
icecores <- doc2$dataset$dataTable[[3]]$attributeList$attribute
snow <- doc2$dataset$dataTable[[4]]$attributeList$attribute


# assign annotations back to be-7 attributes
# aerosols
for(i in 10:11){
  doc$dataset$dataTable[[1]]$attributeList$attribute[[i]]$annotation <- 
    aerosols[[i]]$annotation
}


# seawater
for(i in 7:8){
  doc$dataset$dataTable[[2]]$attributeList$attribute[[i]]$annotation <- 
    seawater[[i]]$annotation
}


# icecores
for(i in 11:12){
  doc$dataset$dataTable[[3]]$attributeList$attribute[[i]]$annotation <- 
    icecores[[i]]$annotation
}


# snow
for(i in 12:13){
  doc$dataset$dataTable[[4]]$attributeList$attribute[[i]]$annotation <- 
    snow[[i]]$annotation
}

eml_validate(doc)


# -- update the package -- ##
# write EML
eml_path <- "~/Scratch/Beryllium_7_concentrations_in_aerosols_seawater_.xml"
write_eml(doc, eml_path)



# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)



## -------------------------------------------------------------------------- ##

# load newest version
packageId <- "resource_map_urn:uuid:664afc55-62af-4d17-95e7-1e3ddb9a8968"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)
xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


aerosols <- doc$dataset$dataTable[[1]]$attributeList$attribute
seawater <- doc$dataset$dataTable[[2]]$attributeList$attribute
icecores <- doc$dataset$dataTable[[3]]$attributeList$attribute
snow <- doc$dataset$dataTable[[4]]$attributeList$attribute


# icecores
atts <- get_attributes(doc$dataset$dataTable[[3]]$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)
doc$dataset$dataTable[[3]]$attributeList <- set_attributes(atts_edited$attributes)

for(i in 11:12){
  doc$dataset$dataTable[[3]]$attributeList$attribute[[i]]$annotation <- 
    icecores[[i]]$annotation
}

doc$dataset$dataTable[[3]]$attributeList$attribute[[11]]$measurementScale$ratio$unit$customUnit <- 
  "becquerelPerMeterCubed"

doc$dataset$dataTable[[3]]$attributeList$attribute[[12]]$measurementScale$ratio$unit$customUnit <- 
  "becquerelPerMeterCubed"

eml_validate(doc)


# -- update the package -- ##
# write EML
eml_path <- "~/Scratch/Beryllium_7_concentrations_in_aerosols_seawater_.xml"
write_eml(doc, eml_path)



# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)


