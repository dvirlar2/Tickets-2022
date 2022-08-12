# Dataset: Northwest Passage Project seawater dataset, July - August 2019, Canadian Arctic Archipelago.


## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "urn:uuid:28bd2424-1393-4fc3-8039-3b17866e5393"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


# -- add distribution -- #
id <- dataone::generateIdentifier(d1c@mn, "doi")
doc <- eml_add_distribution(doc, id)

eml_validate(doc)


# -- publish the package -- ##
# write EML
eml_path <- "~/Scratch/Northwest_Passage_Project_seawater_dataset_July.xml"
write_eml(doc, eml_path)

# replace eml and add doi
dp <- replaceMember(dp, xml, replacement = eml_path, newId = id)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=TRUE,
                                  accessRules = myAccessRules, quiet=FALSE)
