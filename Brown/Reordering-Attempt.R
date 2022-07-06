# Daphne Virlar-Knight
# June 8, 2022

# Tasks:
# [ ] Re-order entities of Brown dataset so that .zip file is first

## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# run token in console

# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

# Get the package
packageId <- "resource_map_doi:10.18739/A2FF3M173"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

# Get the metadata id
xml <- selectMember(dp, "sysmeta@fileName", ".xml")

# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))


## -- reorder entities -- ##
# I re-ordered the spatialVector entity to the top of the list by literally 
# downloading the xml file from the website, and then moving the spatialVector
# to the follow immediately after </project> on line 134


# generate doi
doi <- dataone::generateIdentifier(d1c@mn, "DOI")

dp <- replaceMember(dp, xml, 
                    replacement = "Brown/Maps_of_contemporary_subsistence_land_use.xml",
                    newId=doi)


# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=TRUE,
                                  accessRules = myAccessRules, quiet=FALSE)


## -- set rights & access -- ##
# Setting access to all PIDs associated with package
subject <- 'http://orcid.org/0000-0002-1195-7161'


# get list of current pids
pids <- arcticdatautils::get_package(d1c@mn, packageId)

set_rights_and_access(d1c@mn,
                      pids = c(xml, pids$data, packageId),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))



# load in the edited xml
# xml_edit <- system.file("~/Brown/Maps_of_contemporary_subsistence_land_use_in.xml", package = "emld")
# doc2 <- EML::read_eml(xml_edit)
# 
# doc2 <- as_emld(xml_edit)
# 
# #  --------------------------------------------------------------------------- #
# 
# # Create a DataObject and add it to the DataPackage
# dp <- new("DataPackage")
# doIn <- new("DataObject", format="eml://ecoinformatics.org/eml-2.1.1", 
#             filename=system.file('Tickets-2022/Brown/Brown_ReorganizedFiles.xml', package="emld"))
# dp <- addMember(dp, doIn)
# 
# # Use the zipped version of the file instead by updating the DataObject
# dp <- replaceMember(dp, doIn, 
#                     replacement=system.file("Tickets-2022/Brown/Brown_ReorganizedFiles.xml", 
#                                             package="emld"),
#                     formatId="eml://ecoinformatics.org/eml-2.1.1")
# 
# ###
# 
# xml_edit <- system.file("Brown/Brown_ReorganizedFiles.xml", package = "emld")
# emld <- as_emld(xml_edit)
# xml_eml <- emld::as_xml(emld)
# 
# # f <- system.file("extdata/example.xml", package = "emld")
# # emld <- as_emld(f)
# # xml <- as_xml(emld) 
# 
# xml_edit