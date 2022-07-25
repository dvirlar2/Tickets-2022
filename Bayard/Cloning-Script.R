# Creating Bayard CLones

# Thought process: Rather than copying everything over in the web editor, 
# just create a blank form and copy everything over from the clone using 
# object names doc_clone and doc_source


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

# Get the package
packageId <- "resource_map_urn:uuid:847b6fb9-2ec0-48e3-87d3-a5d3c4f3a600"

dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

# Get the metadata id
xml <- selectMember(dp, "sysmeta@fileName", ".xml")

# Read in the metadata
doc_source <- read_eml(getObject(d1c@mn, xml))


## -- Set Up doc_clone -- ##
packageId <- "resource_map_urn:uuid:519b1164-515c-4211-940c-005ff2c35655"

dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc_clone <- read_eml(getObject(d1c@mn, xml))



## --title and abstract -- ##
doc_clone$dataset$title <- stringr::str_replace(doc_source$dataset$title, "Sir Wilfrid Laurier", "Sikuliaq")
# doc_clone$dataset$title <- "Surface sediment samples collected from the Canadian Coast Guard Ship (CCGS) Sir Wilfrid Laurier 2021, Northern Bering Sea to Chukchi Sea"


doc_clone$dataset$abstract <- doc_source$dataset$abstract

doc_clone$dataset$keywordSet <- doc_source$dataset$keywordSet

data_sens <- list(doc_clone$dataset$annotation)
doc_clone$dataset$annotation <- c(data_sens, doc_source$dataset$annotation)


## -- people and parties -- ##
doc_clone$dataset$creator <- doc_source$dataset$creator

doc_clone$dataset$contact <- doc_source$dataset$contact

doc_clone$dataset$publisher <- doc_source$dataset$publisher

doc_clone$dataset$metadataProvider <- doc_source$dataset$metadataProvider


## -- geographic coverage -- ##
doc_clone$dataset$coverage$geographicCoverage <- doc_source$dataset$coverage$geographicCoverage


## -- project info -- ##
doc_clone$dataset$project <- doc_source$dataset$project


## -- methods & sampling -- ##
doc_clone$dataset$methods <- doc_source$dataset$methods


## -- validate & update -- ##
eml_validate(doc_clone)


eml_path <- "~/Scratch/Discrete_water_samples_collected_SQK_2021.xml"
write_eml(doc_clone, eml_path)

# replace eml 
dp <- replaceMember(dp, xml, replacement = eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)

## -- set rights & access -- ##
# Setting access to all PIDs associated with package
subject <- 'http://orcid.org/0000-0002-5011-102X'


# get list of current pids
pids <- arcticdatautils::get_package(d1c@mn, "resource_map_urn:uuid:c5c48e4e-03dd-48f3-85ed-3a71fb20749c")

set_rights_and_access(d1c@mn,
                      pids = c(pids$metadata, pids$resource_map),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))
