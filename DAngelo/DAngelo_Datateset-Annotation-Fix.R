# D' Angelo

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

packageId <- "resource_map_urn:uuid:0db6fd9e-9b43-4ba4-b805-95e612d9d3a6"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))

doc$dataset$annotation <- doc$dataset$annotation[c(1,2)]

doc$dataset$annotation <- list(doc$dataset$annotation[[1]], doc$dataset$annotation[[2]])

eml_validate(doc)
