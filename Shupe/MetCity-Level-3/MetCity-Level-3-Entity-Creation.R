## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:df0abbba-4346-40fe-a90c-ad55d7c56d56"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- retrieve file names from visitor -- ##
files <- list.files("/home/visitor/Shupe/TOWER/Level-3")
  # after checking the pid_to_eml() functions code, I don't think this is necessary.

## -- create entities from pids -- ##
ids <- get_package(d1c@mn, packageId)

# save data pids from working version to a variable
dat_pids <- ids$data

# loop through all pids to create entities
for(i in 1:length(dat_pids)){
  doc$dataset$otherEntity[[i]] <- pid_to_eml_entity(d1c@mn,
                    dat_pids[i],
                    entity_type = "otherEntity"
                    # entityName = files[i],
                    # entityDescription = paste("Description for entity", files[i])
                    )
}

eml_validate(doc)

## -- update package -- ##
eml_path <- "~/Scratch/Met_City_meteorological_and_surface_flux.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE, 
                                  accessRules = myAccessRules, quiet = FALSE)