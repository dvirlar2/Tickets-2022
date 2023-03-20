## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- get dataset -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:c933fe9a-655d-4abd-83e3-a04a9933283f"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))

## -- add dataset categorization -- ##
doc <- eml_categorize_dataset(doc, c("Soil Science", "Plant Science"))

## -- add FAIR -- ##
doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)

## -- NSF Awards -- ##
doc$dataset$project <- eml_nsf_to_project(c("2113432", "1603677"))


## -- add attributes -- ##
data_pid <- selectMember(dp, name = "sysmeta@fileName", value = ".csv")
data <- read.csv(text=rawToChar(getObject(d1c@mn, data_pid)))

roy_atts <- EML::shiny_attributes(data = data)
attributeList <- EML::set_attributes(attributes = roy_atts$attributes) 

# edit microgramPerCentimeterSquared --> forgot the squared part
get_attList <- get_attributes(attributeList)
test_atts <- EML::shiny_attributes(data = NULL, attributes = get_attList$attributes)
attributeList <- EML::set_attributes(attributes = test_atts$attributes) 

# set custom units
# define custom units
custom_units <- test_atts$units # needs to be output from shiny_attributes
unitList <- set_unitList(custom_units, as_metadata = TRUE) # updating the unitList
doc$additionalMetadata <- unitList

# assign att list to entity
doc$dataset$otherEntity[[1]]$attributeList <- attributeList
eml_validate(doc)
  # TRUE

## -- add physicals -- ##
all_pids <- get_package(d1c@mn, packageId, file_names = TRUE)
data_pids <- reorder_pids(all_pids$data, doc) # lines up pids w/correct file

# for loop to assign physicals for each file 
for (i in 1:length(data_pids)){
  doc$dataset$otherEntity[[i]]$physical <- pid_to_eml_physical(d1c@mn, data_pids[[i]])
}

## -- OEs to DTs -- ##
doc <- eml_otherEntity_to_dataTable(doc, 1)

## -- update package -- ##
eml_path <- "~/Scratch/Soil_and_plant_variables_collected_at_brown.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE, 
                                  accessRules = myAccessRules, quiet = FALSE)
