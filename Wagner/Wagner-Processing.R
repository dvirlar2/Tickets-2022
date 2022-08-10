# Wagner -- Transient Electromagnetic Data of the Malaspina Glacier Forelands

## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:5bc7b9e3-22eb-429e-aac6-1b004f0452d4"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- add NSF award -- ##
doc$dataset$project <- eml_nsf_to_project("1929577")


# -- publish the package -- ##
# write EML
eml_path <- "~/Scratch/Transient_Electromagnetic_Data_of_the_Malaspina_Glacier_Forelands.xml"
write_eml(doc, eml_path)


# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)
