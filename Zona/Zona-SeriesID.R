# Assign a Series ID for this dataset:
    # https://arcticdata.io/catalog/view/urn%3Auuid%3A38b9ea29-67ba-4d52-827d-922cbb8e0168

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

packageId <- "resource_map_urn:uuid:9fa81643-d0df-4da4-84e5-18e842c58a70"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


## -- Add Series ID -- ##
# The metadata identifier we're assigning an SID to
xml <- selectMember(dp, "sysmeta@fileName", ".xml")

sys <- getSystemMetadata(d1c@mn, xml)
sys@seriesId <- generateIdentifier(d1c@mn, scheme = 'DOI') #update the scheme argument if it should not be a DOI
updateSystemMetadata(d1c@mn, xml, sys)
