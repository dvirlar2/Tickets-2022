
## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# Load DataOne token

# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")


# Get the package
packageId <- "resource_map_urn:uuid:3fe335e6-2700-4056-b7b0-666a0b95a4dc"

dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")

doc <- read_eml(getObject(d1c@mn, xml))



## -- fix project section -- ## 
# recreate NASA award 1
award1 <- eml$award()
award1$funderName <- "National Aeronautics and Space Administration Cryosphere Program"
award1$awardNumber <- "80NSSC19K0942"
award1$title <- "Representing surface meltwater runoff in Greenland ice sheet models"
award1$funderIdentifier <- NULL
award1$awardUrl <- NULL

# recreate NASA award 2
award2 <- eml$award()
award2$funderName <- "National Aeronautics and Space Administration Cryosphere Program"
award2$awardNumber <- "NNX14AH93G"
award2$title <- "Representing surface meltwater runoff in Greenland ice sheet models"
award2$funderIdentifier <- NULL
award2$awardUrl <- NULL


eml_award <- list(award1, award2)

doc$dataset$project$award <- NULL
doc$dataset$project$award <- eml_award

# edit project title
doc$dataset$project$title <- "Representing surface meltwater runoff in Greenland ice sheet models"


# Edit the personnel
doc$dataset$project$personnel <- NULL
doc$dataset$project$personnel <- vector("list", 2)

 
# person 1
doc$dataset$project$personnel[[1]]$individualName$givenName <- "Asa"
doc$dataset$project$personnel[[1]]$individualName$surName <- "Rennermalm"

# role 1
doc$dataset$project$personnel[[1]]$role <- "coPrincipalInvestigator"


# person 2
doc$dataset$project$personnel[[2]]$individualName$givenName <- "Laurence"
doc$dataset$project$personnel[[2]]$individualName$surName <- "C. Smith"

# role 2
doc$dataset$project$personnel[[2]]$role <- "principalInvestigator"


eml_validate(doc)



## -- update package -- ##
# Write EML
eml_path <- "~/62_days_of_Supraglacial_streamflow_from.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# publish doi
dp <- replaceMember(dp, xml, replacement=eml_path)
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE, quiet=FALSE)
