# Daphne Virlar-Knight
# June 9 2022

# Tasks
# Move over hex data from original Kapsar dataset into the new split dataset

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
target_packageId <- "resource_map_urn:uuid:4b394e89-763b-4109-93e4-b59a16255a5e"
target_dp  <- getDataPackage(d1c, identifier = target_packageId, lazyLoad=TRUE, quiet=FALSE)


# Get the metadata id
target_xml <- selectMember(target_dp, name = "sysmeta@fileName", value = ".xml")

target_doc <- read_eml(getObject(d1c@mn, target_xml))



## -- Carry Over Attributes for the Hex Data-- ##

for (i in 1:length(target_doc$dataset$otherEntity)){ 
  target_doc$dataset$otherEntity[[i]]$attributeList <-   
            source_doc$dataset$spatialVector[[i]]$attributeList
}


eml_validate(target_doc)




## -- Fix FormatIds -- ##
for(i in 1:length(target_doc$dataset$otherEntity)){
    target_doc$dataset$otherEntity[[i]]$entityType <- "application/vnd.shp+zip"
}


## -- Convert to spatialVectors -- ##
# get pids of otherEntities
all_pids <- get_package(d1c@mn, target_packageId, file_names = TRUE)
all_pids <- reorder_pids(all_pids$data, target_doc)

spatialVector <- vector("list", length = length(target_doc$dataset$otherEntity))

for(i in seq_along(target_doc$dataset$otherEntity)){ #length of vector pids
  spatialVector[[i]] <- 
    pid_to_eml_entity(d1c@mn,
                      all_pids[[i]],
                      entity_type = "spatialVector",
                      entityName = target_doc$dataset$otherEntity[[i]]$entityName,
                      entityDescription =
                        target_doc$dataset$otherEntity[[i]]$entityDescription,
                      attributeList =
                        target_doc$dataset$otherEntity[[i]]$attributeList,
                      geometry = "Polygon",
                      spatialReference = list(horizCoordSysName = "GCS_North_American_1983"))
}

# assign back to doc
target_doc$dataset$spatialVector <- spatialVector

# null otherEntities -- duplicates cause problems
target_doc$dataset$otherEntity <- NULL


# reverse order of spatial vectors
target_doc$dataset$spatialVector <- rev(target_doc$dataset$spatialVector)



## -- add entity descriptions -- ##

for(i in 1:length(target_doc$dataset$spatialVector)){

    t <- target_doc$dataset$spatialVector[[i]]$entityName
  t_split <- strsplit(t, split = "_|.zip")
  
  # put split string into entity description
  target_doc$dataset$spatialVector[[i]]$entityDescription <- 
    paste("Vessel data generated from satellite-based automatic identification system (AIS). Data include summaries of vessel speed, number of unique ships, and number of operating days (vessel x date combinations) aggregated by year, month, and ship type. This shapefile contains data during", month.name[as.numeric(t_split[[1]][3])], 
          t_split[[1]][2])
}



## -- Copy Over Creator & Awards -- ##
# creator info
target_doc$dataset$creator <- source_doc$dataset$creator

# contact info
target_doc$dataset$contact <- source_doc$dataset$contact

# funding award
target_doc$dataset$project$award <- source_doc$dataset$project$award
target_doc$dataset$project$title <- source_doc$dataset$project$title
target_doc$dataset$project$personnel <- source_doc$dataset$project$personnel 


## -- fix the bounding coordinates -- ##
target_doc$dataset$coverage$geographicCoverage$boundingCoordinates$westBoundingCoordinate <- "160"

target_doc$dataset$coverage$geographicCoverage$boundingCoordinates$eastBoundingCoordinate <- "-145"

# make sure i haven't broken anything
eml_validate(target_doc)
  # TRUE


## -- add publisher information -- ##
# FAIR
target_doc$dataset$publisher <- source_doc$dataset$publisher


## -- dataset categorization -- ##
target_doc <- eml_categorize_dataset(target_doc, "Human Geography")



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




## -- edit the format IDs -- ##
# this changes the physical format name
for(i in 1:length(target_doc$dataset$spatialVector)){
  target_doc$dataset$spatialVector[[i]]$physical$dataFormat$externallyDefinedFormat$formatName <- "application/vnd.shp+zip"
}

eml_validate(target_doc)


target_doc$dataset$spatialVector[[1]]

selectMember(target_dp, name="sysmeta@formatId", value="application/vnd.shp+zip")
hex1_pid <- selectMember(target_dp, name = "sysmeta@fileName", value = "SpeedHex_2015_01.zip")

hex1_sysmeta <- getSystemMetadata(d1c@mn, hex1_pid)



# collect all_pids
all_pids <- get_package(d1c@mn, target_packageId, file_names = TRUE)
all_pids <- reorder_pids(all_pids$data, target_doc)


# create a list for sysmeta data
sysmeta <- list()

# for loop to fill out sysmeta
for(i in 1:length(all_pids)){
  sysmeta[[i]] <- getSystemMetadata(d1c@mn, all_pids[[i]])
}


# for loop to fix format ID slot
for(i in 1:length(all_pids)){
  sysmeta[[i]]@formatId <- "application/vnd.shp+zip"
}


# update the sysmeta
for(i in 1:length(all_pids)){
  updateSystemMetadata(d1c@mn, all_pids[[i]], sysmeta[[i]])
}




## -- update package -- ##
eml_path <- "~/Scratch/North_Pacific_and_Arctic_Marine_Vessel_Traffic_Hex.xml"
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
