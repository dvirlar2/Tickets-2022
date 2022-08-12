d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

# source dataset
packageId <- "resource_map_doi:10.18739/A2NV99C36" # this is the source package ID
dp <- dataone::getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")
source_doc <- read_eml(getObject(d1c@mn, xml)) # reading in the metadata


# 2018 dataset
packageId2018 <- "resource_map_urn:uuid:9250fac8-1900-4e0c-be6b-a01583198569" # this is the 2018 clone package ID
dp2018 <- dataone::getDataPackage(d1c, identifier = packageId2018, lazyLoad=TRUE, quiet=FALSE)
xml2018 <- selectMember(dp2018, name = "sysmeta@fileName", value = ".xml")
clone2018_doc <- read_eml(getObject(d1c@mn, xml2018)) # reading in the metadata


# 2019 dataset
packageId2019 <- "resource_map_urn:uuid:fcadd752-930b-47ab-983b-86f68e121140" # this is the 2019 clone package ID
dp2019 <- dataone::getDataPackage(d1c, identifier = packageId2019, lazyLoad=TRUE, quiet=FALSE)
xml2019 <- selectMember(dp2019, name = "sysmeta@fileName", value = ".xml")
clone2019_doc <- read_eml(getObject(d1c@mn, xml2019)) # reading in the metadata


## -- convert other entity to data table -- ##
clone2019_doc$dataset$otherEntity[[1]]$entityName

# change to data table
clone2019_doc <- eml_otherEntity_to_dataTable(clone2019_doc, 1, validate_eml = F)

# add physical 
csv_pid <- selectMember(dp2019, name = "sysmeta@fileName", value = ".csv")
clone2019_doc$dataset$dataTable[[1]]$physical <- pid_to_eml_physical(d1c@mn, csv_pid)

eml_validate(clone2019_doc)
# [1] FALSE
# attr(,"errors")
# [1] "Element 'dataTable': Missing child element(s). Expected is one of ( physical, coverage, methods, additionalInfo, annotation, attributeList )."


## -- carry over 2019 attributes -- ##
clone2019_doc$dataset$dataTable[[1]]$attributeList <- source_doc$dataset$dataTable$attributeList
eml_validate(clone2019_doc)
# [1] TRUE
# attr(,"errors")
# character(0)


## -- update package -- ##
eml_path <- "~/Scratch/Benthic_macroinfaunal_samples_collected_from_the_SWL_2019.xml"
write_eml(clone2019_doc, eml_path)

# replace eml 
dp2019 <- replaceMember(dp2019, xml2019, replacement = eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp2019, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)
