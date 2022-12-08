# Topkok/Powell dataset

## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:6cf28bff-2dc0-4a07-9db2-7b22bf36b456"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- add award -- ##
doc$dataset$project <- eml_nsf_to_project("2028928")


## -- add FAIR -- ##
doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)


## -- add dataset categorization -- ##
doc <- eml_categorize_dataset(doc, "Sociology")


## -- update package -- ##
eml_path <- "~/Scratch/COVID_19_impacts_and_response_in_Juneau_Alaska.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE, 
                                  accessRules = myAccessRules, quiet = FALSE)