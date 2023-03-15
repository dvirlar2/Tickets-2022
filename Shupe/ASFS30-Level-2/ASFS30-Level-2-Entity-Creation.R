## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- load token -- ##
options(dataone_token = "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJodHRwOlwvXC9vcmNpZC5vcmdcLzAwMDAtMDAwMy0zNzA4LTYxNTQiLCJmdWxsTmFtZSI6IkRhcGhuZSBWaXJsYXItS25pZ2h0IiwiaXNzdWVkQXQiOiIyMDIzLTAyLTIzVDIwOjM5OjAxLjEwNyswMDowMCIsImNvbnN1bWVyS2V5IjoidGhlY29uc3VtZXJrZXkiLCJleHAiOjE2NzcyNDk1NDEsInVzZXJJZCI6Imh0dHA6XC9cL29yY2lkLm9yZ1wvMDAwMC0wMDAzLTM3MDgtNjE1NCIsInR0bCI6NjQ4MDAsImlhdCI6MTY3NzE4NDc0MX0.XufMNMmfoQDx3oXEhndEy9865Cjx97Rww_IAGbQbPsd7je2r_vNomwDvWEfYo8pzk62Ilc9rrJe7KlNCERp_ujMESqeuT_z2od39ahnbrHN05Bdb7DicwwnDZR0LlxAfLOV83gp4MyF462uiO5KevjTgqeIJzOAa-MHpuliIcM3VSzt1lJ_FP3XEz9EYFICF3stH_dPCAJLpuEwL8dQ0phRzWKOC829FuqO9-nFzTsg0HMcufLVYVikdC7Z74-hTGwkE1bnPYZMA_gT6GS5PejlozzcMmsPJxlBEh_-1LKzwwLr9CDRu8OCcHlaaT4QAZZCEP8TSIEVTeM2Ehcug7g")

## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:ca7ffcab-9066-4439-bd7d-d64ec0d13306"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- create entities from pids -- ##
ids <- get_package(d1c@mn, packageId)

# save data pids from working version to a variable
dat_pids <- ids$data

# loop through all pids to create entities
for(i in 1:length(dat_pids)){
  doc$dataset$otherEntity[[i]] <- pid_to_eml_entity(d1c@mn,
                                                    dat_pids[i],
                                                    entity_type = "otherEntity"
  )
}

eml_validate(doc)

## -- update package -- ##
eml_path <- "~/Scratch/Atmospheric_Surface_Flux_Station_30_measurements.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE, 
                                  accessRules = myAccessRules, quiet = FALSE)