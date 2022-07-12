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

packageId <- "resource_map_urn:uuid:a4b38680-b7ce-466c-a626-2781f2c0ffbd"
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


## -- add custom units -- ##
# save enumerated domain info. For some reason it's not being retained in Shiny.
month_att <- doc$dataset$dataTable$attributeList$attribute[[5]]
day_att <- doc$dataset$dataTable$attributeList$attribute[[6]]
burn_att <- doc$dataset$dataTable$attributeList$attribute[[11]]


# adding custom units for:
  #X cond -- microsiemensPerCentimeter (uS/cm)
  # SUVA -- literPerMilligramPerMeter (L/mg/m)
  #X CO2atm, CO2ppm, CH4atm, CH4ppm -- partsPerMillion (ppm)
  # pCO2, pCH4 -- microatmospheres
  # CO2flux -- micromolePerMeterSquaredPerSecond (µmol/m^2/sec)
  # CH4flux -- nanomolePerMeterSquaredPerSecond (nmol/m^2/sec)
atts <- get_attributes(doc$dataset$dataTable$attributeList)
atts_edited <- shiny_attributes(attributes = atts$attributes)
doc$dataset$dataTable$attributeList <- set_attributes(atts_edited$attributes)


# assign back enumerated domains
month_att <- doc$dataset$dataTable$attributeList$attribute[[5]]
day_att <- doc$dataset$dataTable$attributeList$attribute[[6]]
burn_att <- doc$dataset$dataTable$attributeList$attribute[[11]]




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



# ---------------------------------------------------------------------------- #
# July 11, 2022 Update

# Fix the SUVA custom unit
atts <- get_attributes(doc$dataset$dataTable$attributeList)

atts_edited <- shiny_attributes(attributes = atts$attributes)
  # need to add back enumerated domain for month, day, burn

custom_units <- atts_edited$units

unitlist <- set_unitList(custom_units, as_metadata = TRUE)
doc$additionalMetadata <- unitlist

# get the enumerated domain for month, day, burn
enumDomains <- doc$dataset$dataTable$attributeList


# set the edited atts back to the doc
doc$dataset$dataTable$attributeList <- set_attributes(attributes = atts_edited$attributes,
                                                      factors = atts_edited$factors)

# check on missing value codes
doc$dataset$dataTable$attributeList$attribute[[23]]$missingValueCode
  # random numbers checked -- looks good!

# check on enumerated domains
# Month
doc$dataset$dataTable$attributeList$attribute[[5]]$measurementScale <- enumDomains$attribute[[5]]$measurementScale

# Day
doc$dataset$dataTable$attributeList$attribute[[6]]$measurementScale <- enumDomains$attribute[[6]]$measurementScale

# Burn
doc$dataset$dataTable$attributeList$attribute[[11]]$measurementScale <- enumDomains$attribute[[11]]$measurementScale

eml_validate(doc)
  # TRUE 



# -- add distribution -- #
id <- generateIdentifier(d1c@mn, "doi")
doc <- eml_add_distribution(doc, id)

eml_validate(doc)


# -- publish the package -- ##
# write EML
eml_path <- "~/Scratch/Wildfire_effects_on_aquatic_chemistry_Yukon.xml"
write_eml(doc, eml_path)


# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path, newId=id)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=TRUE,
                                  accessRules = myAccessRules, quiet=FALSE)
