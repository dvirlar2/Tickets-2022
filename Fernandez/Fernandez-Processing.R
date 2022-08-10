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

packageId <- "resource_map_urn:uuid:340df867-58c2-4c00-880a-3eee4c66b3cf"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


## -- awards -- ##
doc$dataset$project <- eml_nsf_to_project("1534055")

eml_award2 <- eml$award()

eml_award2$funderName <- "Belmont Forum, with support by the National Science Foundation, Research Council of Norway, and Nordforsk"
eml_award2$awardNumber <- "765"
eml_award2$title <- "Bioeconomic Analysis for Arctic Marine Resource Governance and Policy, 2015-2022"
eml_award2$funderIdentifier <- NULL
eml_award2$awardUrl <- NULL


eml_award3 <- eml$award()

eml_award3$funderName <- "Danish Ministry for Science and Higher Education Award"
eml_award3$awardNumber <- "6144-00090B"
eml_award3$title <- "Bioeconomic Analysis for Arctic Marine Resource Governance and Policy, 2015-2022"
eml_award3$funderIdentifier <- NULL
eml_award3$awardUrl <- NULL


eml_award4 <- eml$award()

eml_award4$funderName <- "Nordic Council of Ministers"
eml_award4$awardNumber <- "A17450"
eml_award4$title <- "Bioeconomic Analysis for Arctic Marine Resource Governance and Policy, 2015-2022"
eml_award4$funderIdentifier <- NULL
eml_award4$awardUrl <- NULL

eml_award <- list(eml_award2, eml_award3, eml_award4)

doc$dataset$project$award <- c(doc$dataset$project$award, eml_award) 

#edit the title to match the dataset
doc$dataset$project$title <- "Belmont Forum Bioeconomic Analysis for Arctic Marine Resource Governance and Policy, 2015-2022"

eml_validate(doc)


doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)


data_pid <- selectMember(dp, name = "sysmeta@fileName", value = "arcticdatafile.pdf")
physical <- arcticdatautils::pid_to_eml_physical(d1c@mn, data_pid)

doc$dataset$otherEntity$physical <- physical


doc$dataset$otherEntity$entityType <- "application/pdf"


doc <- eml_categorize_dataset(doc, "Economics")


## -- update package -- ##
# write EML
eml_path <- "~/Scratch/Bioeconomic_Analysis_for_Arctic_Marine_Resource.xml"
write_eml(doc, eml_path)

# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)


## ------------------------------------------
# -- add distribution -- #
doi <- generateIdentifier(d1c@mn, "doi")
doc <- eml_add_distribution(doc, doi)


# -- publish the package -- ##
# write EML
eml_path <- "~/Scratch/Bioeconomic_Analysis_for_Arctic_Marine_Resource.xml"
write_eml(doc, eml_path)


# replace eml and add doi
dp <- replaceMember(dp, xml, replacement = eml_path, newId = doi)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=TRUE,
                                  accessRules = myAccessRules, quiet=FALSE)
