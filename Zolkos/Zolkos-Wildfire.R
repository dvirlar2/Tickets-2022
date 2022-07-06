# Daphne Virlar-Knight
# June 24 2022

# Dataset: https://arcticdata.io/catalog/view/urn%3Auuid%3Adc611d4a-2e90-4519-b3e1-cb2397360af1#urn%3Auuid%3Aee978973-1fc4-4f94-8097-88ade8b3729f



## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:aeb90c36-95ad-4298-894a-51bbb78fd8dc"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")

doc <- read_eml(getObject(d1c@mn, xml))



## -- add missing value codes -- ## 

for(i in c(3:6, 13:28, 30:34, 36:47, 49:51)){
  doc$dataset$dataTable$attributeList$attribute[[i]]$missingValueCode <- "NA"
  doc$dataset$dataTable$attributeList$attribute[[i]]$missingValueCodeExplanation <- 
    "Data not measured."
}


## -- attribute descriptions -- ##
doc$dataset$dataTable$attributeList$attribute[[1]]$attributeDefinition <- 
  "Sample identification. An identifier which contains Kit, and also additional information specific to an individual research project, for which the rationale behind this information is no longer known or accessible."


doc$dataset$dataTable$attributeList$attribute[[2]]$attributeDefinition <- 
  "Kit identification. A code specific to an individual research project, for which the rationale behind the numbering is no longer known or accessible."


## -- edit awards -- ##
doc$dataset$project$award[[4]]$title <- doc$dataset$title


## -- edit attributes -- ##
# lat, long, and temp from ratio to interval
# lat
doc$dataset$dataTable$attributeList$attribute[[7]]$measurementScale$ratio <- NULL
doc$dataset$dataTable$attributeList$attribute[[7]]$measurementScale$interval$unit$standardUnit <- "degree"
doc$dataset$dataTable$attributeList$attribute[[7]]$measurementScale$interval$numericDomain$numberType <- "real"


# long
doc$dataset$dataTable$attributeList$attribute[[8]]$measurementScale$ratio <- NULL
doc$dataset$dataTable$attributeList$attribute[[8]]$measurementScale$interval$unit$standardUnit <- "degree"
doc$dataset$dataTable$attributeList$attribute[[8]]$measurementScale$interval$numericDomain$numberType <- "real"


# temp
doc$dataset$dataTable$attributeList$attribute[[14]]$measurementScale$ratio <- NULL
doc$dataset$dataTable$attributeList$attribute[[14]]$measurementScale$interval$unit$standardUnit <- "celsius"
doc$dataset$dataTable$attributeList$attribute[[14]]$measurementScale$interval$numericDomain$numberType <- "real"

eml_validate(doc)



# adding custom units for:
  # cond -- microsiemensPerCentimeter (uS/cm)
  # SUVA -- literPerMilligramPerMeter (L/mg/m)
  # CO2atm, CO2ppm, CH4atm, CH4ppm -- partsPerMillion (ppm)
  # pCO2, pCH4 -- microatmospheres
  # CO2flux -- micromolePerMeterSquaredPerSecond (µmol/m^2/sec)
  # CH4flux -- nanomolePerMeterSquaredPerSecond (nmol/m^2/sec)
atts <- get_attributes(doc$dataset$dataTable$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)
doc$dataset$dataTable$attributeList <- set_attributes(atts_edited$attributes)


# manually fix SUVA custom unit
doc$dataset$dataTable$attributeList$attribute[[28]]$measurementScale$ratio$unit$customUnit <-
  "literPerMilligramPerMeter"


# read in custom units csv file
custom_units <- read.csv("~/Tickets-2022/Zolkos/Custom_Units-Zolkos.csv")
unitlist <- set_unitList(custom_units, as_metadata = TRUE)
doc$additionalMetadata <- unitlist

eml_validate(doc)







## -- update package -- ##
eml_path <- "~/Scratch/Wildfire_effects_on_aquatic_chemistry_Yukon.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)
