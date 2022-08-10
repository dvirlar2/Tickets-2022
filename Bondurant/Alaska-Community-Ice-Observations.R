# Editing Bondurant Alaska Community Ice Observations Dataset
# https://arcticdata.io/catalog/view/urn%3Auuid%3Ad3710d8d-54df-4460-add7-233a6c7e1aa2#urn%3Auuid%3A0496feab-0c00-4f97-ab95-8914ab81543d


## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:16acd933-9c53-40d2-ba6f-8efa2383a5fc"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- remove funding line -- ##
doc$dataset$project$funding <- NULL


## -- add dataset categorization -- ##
doc <- eml_categorize_dataset(doc, "Cryology")


## -- update package -- ##
eml_path <- "~/Scratch/Alaska_Community_Ice_Observations_2019_2022.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)
