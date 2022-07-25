# Zygmunt

## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:47a24059-e779-49b1-9bfa-4fa0be9b2797"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- format ID -- ##
# fix word doc format id
docx <- selectMember(dp, "sysmeta@fileName", ".docx")

sysmeta <- getSystemMetadata(d1c@mn, docx)

# Example of setting the formatId slot
sysmeta@formatId <- "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

updateSystemMetadata(d1c@mn, docx, sysmeta)

## -- Project Section -- ##
eml_award <- eml$award()
eml_award$funderName <- "Research Council of Norway through the IntPart project Arctic Offshore and Coastal Engineering in Changing Climate; 2017"
eml_award$awardNumber <- "274951"
eml_award$title <- "Arctic Offshore and Coastal Engineering in Changing Climate."
eml_award$funderIdentifier <- NULL
eml_award$awardUrl <- NULL


# add eml award to project section
doc$dataset$project$award <- eml_award

# remove funding section
doc$dataset$project$funding <- NULL

# validate
eml_validate(doc)


# -- publish the package -- ##
# write EML
eml_path <- "~/Scratch/Tidal_constituents_for_the_Spitsbergen_Bank.xml"
write_eml(doc, eml_path)


# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)
