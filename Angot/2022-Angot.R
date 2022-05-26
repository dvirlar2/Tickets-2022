# Daphne Virlar-Knight
# May 9, 2022


# Ticket 24380: https://support.nceas.ucsb.edu/rt/Ticket/Display.html?id=24380

# Dataset: https://arcticdata.io/catalog/view/urn:uuid:2938bca9-1b71-41d0-895c-3bcf5878111a


# Notes
# Dataset had already been published, PI made minor revisions in title and
# in methodology. Only assigning a new DOI.


## -- load libraries -- ##
# general
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)



## -- read in data -- ##
# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")


# Get the package
packageId <- "resource_map_urn:uuid:cf13d368-339e-4b59-abe3-abb2ce2ae86d"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)



# Get the metadata id
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")


# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))


## -- fix funding section -- ##
awards <- "1914781"
proj <- eml_nsf_to_project(awards, eml_version = "2.2.0")

doc$dataset$project <- proj
eml_validate(doc)




## -- publish with a DOI -- ##
# Write EML
eml_path <- "~/Scratch/Ambient_air_ozone_mole_fractions_measured_in_the.xml"
write_eml(doc, eml_path)

# generate doi
doi <- dataone::generateIdentifier(d1c@mn, "DOI")

# change access
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

# publish
dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)  
newPackageId <- uploadDataPackage(d1c, dp, public=TRUE, quiet=FALSE)



# Manually set ORCiD
subject <- 'http://orcid.org/0000-0003-4673-8249'


# Get data pids
ids <- getIdentifiers(dp)

# set rights
set_rights_and_access(d1c@mn,
                      pids = c(ids, packageId),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))
