# McRaven 2: Shipboard hydrographic measurements from the Fate of freshwater and heat from the West Greenland Current project. 


## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:f6a168fb-bb8e-4f7c-b7e6-6f2b74f914c4"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- edit entity descriptions -- ##
# get index of only files that end in .cnv
cnv_index <- which_in_eml(doc$dataset$otherEntity, "entityName", 
             function(x) {
               grepl(".cnv", x)})

# create doc with only .cnv entities
cnv_ents <- doc$dataset$otherEntity[cnv_index]


# create entity descriptions based on 
for(i in cnv_index){
  
  t <- doc$dataset$otherEntity[[i]]$entityName
  t_split <- strsplit(t, split = "_|\\.") # matches by "_" OR "."
  
  # put split string into entity description
  doc$dataset$otherEntity[[i]]$entityDescription <- 
    paste("Vertical profile cast performed using a SeaBird 911plus CTD and deck unit configured to measure pressure, temperature, conductivity, oxygen, beam transmission and fluorescence. Raw CTD data were converted from HEX to human-readable text file containing data in physical units with a
detailed header preceding data. Data within this file was gathered aboard the United States Coast Guard vessel Healy, cruise ID HLY2101, at station number", t_split[[1]][2])
}



## -- update package -- ##
eml_path <- "~/Scratch/Shipboard_hydrographic_measurements_from_the_Fate_of_freshwater_and_heat_from_the_West_Greenland_Current_project.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)
