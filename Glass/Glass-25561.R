## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:c65e1806-c175-44cd-a321-5289466341d2"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- convert OE to DT -- ##
doc <- eml_otherEntity_to_dataTable(doc, 1:3)

eml_validate(doc)

# edit lat/lon
attributeList <- EML::get_attributes(doc$dataset$dataTable[[3]]$attributeList)
attList <- EML::shiny_attributes(data = NULL, attributes = attributeList$attributes)

doc$dataset$dataTable[[3]]$attributeList <- EML::set_attributes(attributes = attList$attributes)

eml_validate(doc)


## -- add physicals -- ##
all_pids <- get_package(d1c@mn, packageId, file_names = TRUE)
data_pids <- reorder_pids(all_pids$data, doc) # lines up pids w/correct file

# for loop to assign physicals for each file 
for (i in 1:length(data_pids)){
  doc$dataset$dataTable[[i]]$physical <- pid_to_eml_physical(d1c@mn, data_pids[[i]])
}


## -- add dataset categorization -- ##
doc <- eml_categorize_dataset(doc, "Ecology")


## -- add FAIR -- ##
doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)


## -- add nsf award -- ##
doc$dataset$project <- eml_nsf_to_project("2114164")


## -- update package -- ##
eml_path <- "~/Scratch/Fish_length_and_ice_thickness_measurements_from.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE, 
                                  accessRules = myAccessRules, quiet = FALSE)