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

packageId <- "resource_map_urn:uuid:ba72f793-1507-4c95-bed3-eee1f3723e00"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


## -- Get Raster Data -- ## 