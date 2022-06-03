# Daphne Virlar-Knight
# May 31, 2022


## -- Tasks -- ## 
# [X] Change xml name per Byron's request
# [X] Change file per Byron's request --> did this in web editor
# [ ] Don't forget to issue a new DOI once processing has been completed


## -- Set Up -- ##
library(EML)
library(arcticdatautils)
library(datapack)
library(dataone)


# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

# Load Dataset
packageId <- "resource_map_urn:uuid:71696a38-20a4-4b4d-ad62-8904ad704550"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")

doc <- read_eml(getObject(d1c@mn, xml))



# change object name (physical) to match entity name
doc$dataset$dataTable$physical$objectName <- doc$dataset$dataTable$entityName

eml_validate(doc)
# awesome, that didn't cause any glitches


## -- update package w/new xml name -- ##
# Write EML
eml_path <- "~/Scratch/DMS_CU_dry_air_mole_fraction_min_avg.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


# make public
dp <- replaceMember(dp, xml, replacement=eml_path)
newPackageId <- uploadDataPackage(d1c, dp, 
                                  accessRules = myAccessRules,
                                  public=TRUE, quiet=FALSE)


## -- set rights and access -- ## 
# Manually set ORCiD

# Helene
subject1 <- 'http://orcid.org/0000-0003-4673-8249'

# Byron
subject2 <- 'http://orcid.org/0000-0002-3366-6269'

# Get data pids
ids <- getIdentifiers(dp)

# set rights for Byron
set_rights_and_access(d1c@mn,
                      pids = c(ids, newPackageId),
                      subject = subject2,
                      permissions = c('read', 'write', 'changePermission'))


# set access for Helene
set_access(d1c@mn, c(ids, newPackageId), subject1)

