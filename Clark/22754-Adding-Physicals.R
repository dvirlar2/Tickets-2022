## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:aa474ae8-5894-4a03-99e7-55d8da60c406"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- add .cor physicals -- ##
cor_index <- which_in_eml(doc$dataset$dataTable, "entityName", 
                      function(x) {
                        grepl(".cor", x)
                      })

for(i in cor_index){
  cor_pid <- selectMember(dp, name = "sysmeta@fileName", value = doc$dataset$dataTable[[i]]$entityName)
  doc$dataset$dataTable[[i]]$physical <- pid_to_eml_physical(d1c@mn, cor_pid)
}


## -- fix other entity physicals -- ##
# add physicals - Erika's code
for (i in seq_along(doc$dataset$otherEntity)) {
  otherEntity <- doc$dataset$otherEntity[[i]]
  id <- otherEntity$id
  
  if (!grepl("urn-uuid-", id)) {
    warning("otherEntity ", i, " is not a pid")
    
  } else {
    id <- gsub("urn-uuid-", "urn:uuid:", id)
    physical <- arcticdatautils::pid_to_eml_physical(d1c@mn, id)
    doc$dataset$otherEntity[[i]]$physical <- physical
  }
}





## -- update package -- ##
eml_path <- "~/Scratch/Ground_Penetrating_Radar_data_surrounding_beaver_ponds.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE, 
                                  accessRules = myAccessRules, quiet = FALSE)
