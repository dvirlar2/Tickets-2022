# Paxman pre-assigned DOI:
doi <- "doi:10.18739/A2280509Z"


## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:086da80c-a4d9-4c72-856e-c98508f0e401"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


# update readme description
doc$dataset$otherEntity$entityDescription <- "Additional dataset information. README includes information regarding: data description, version of the data product, data format and coverage, reading .nc files, data usage, citation, funding and acknowledgements, as well as contact information."

eml_validate(doc)


# -- publish the package -- ##
# write EML
eml_path <- "~/Scratch/Grid_files_of_the_total_isostatic_response.xml"
write_eml(doc, eml_path)


# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=TRUE,
                                  accessRules = myAccessRules, quiet=FALSE)


## -- set rights & access -- ##
# Setting access to all PIDs associated with package
subject <- 'http://orcid.org/0000-0003-1787-7442'


# get list of current pids
pids <- arcticdatautils::get_package(d1c@mn, packageId)

set_rights_and_access(d1c@mn,
                      pids = c(xml, pids$data, packageId),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))


