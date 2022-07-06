# Daphne Virlar-Knight
# June 27, 2022

# Processing for autoethnographic dataset
# Edited geography in web editor. PI originally put 54.113761 for all

## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_doi:10.18739/A2QR4NS0Z"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))



## -- Award Section -- ##
# add NSF award
doc$dataset$project <- eml_nsf_to_project("2013436")


# edit PI name
doc$dataset$project$personnel[[2]]$individualName$givenName <- "Dana-Ain"
doc$dataset$project$personnel[[2]]$individualName$surName <- "Davis"


## -- Dataset Categorization -- ##
doc <- eml_categorize_dataset(doc, "Anthropology")


## -- update package -- ##
eml_path <- "~/Scratch/Dissertation_research_Indigenous_Land_Defence.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)


# -- publish the package -- ##
# write EML
eml_path <- "~/Scratch/Dissertation_research_Indigenous_Land_Defence.xml"
write_eml(doc, eml_path)

# generate doi
doi <- dataone::generateIdentifier(d1c@mn, "DOI")

# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=TRUE,
                                  accessRules = myAccessRules, quiet=FALSE)
