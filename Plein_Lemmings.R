# Brown Lemming Herbivory Experiment Data, Alaskan Arctic (summers 2018, 2019).
# 2022

# Ticket: https://support.nceas.ucsb.edu/rt/Ticket/Display.html?id=24353
# Dataset: https://arcticdata.io/catalog/view/urn%3Auuid%3Ad0d063c3-5a3e-439f-ab1e-3c66acfeff39


## -- load libraries -- ##
library(dataone)
library(datapack)
library(arcticdatautils)
library(EML)


## -- read in the metadata -- ##
# Reminder: Get server token, and run it in the console

# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")


# Get the package
packageId <- "resource_map_urn:uuid:cdca7f83-ffab-45cd-8db6-7cef9193803a"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)



# Get the metadata id
# This works when there is no other xml file in the data submission. If there is
# more than one xml file, the line below will assign multiple pids to the xml object
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")


# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))


## -- Update Awards Section -- ##
# If one NSF award:
# doc$dataset$project <- eml_nsf_to_project("nsf id here", eml_version = "2.2.0")
# If two or more NSF awards:
doc$dataset$project <- eml_nsf_to_project(c("1204263", "1702797", "1932900"),
                                          eml_version = "2.2.0")

nsf_awards <- doc$dataset$project$award
# If the project has non-NSF awards,
# Add non-NSF Award
eml_award <- eml$award()
eml_award$funderName <- "NASA ABoVE" # ex: National Geographic Society
eml_award$awardNumber <-"NNX15AT74A"
eml_award$title <- "Brown Lemming Herbivory Experiment Data, Alaskan Arctic (summers 2018, 2019)"

eml_award_t <- eml$award()
eml_award_t$funderName <- "NASA ABoVE" # ex: National Geographic Society
eml_award_t$awardNumber <- "NNX16AF94A"
eml_award_t$title <- "Brown Lemming Herbivory Experiment Data, Alaskan Arctic (summers 2018, 2019)"

# second non-NSF Award
eml_award2 <- eml$award()
eml_award2$funderName <- "European Union's Horizon 2020"
eml_award2$awardNumber <- "727890"
eml_award2$title <- "Research and Innovation Program"

# third non-NSF Award
eml_award3 <- eml$award()
eml_award3$funderName <- "Natural Environment Research Council"
eml_award3$awardNumber <- "NE/P002552/1"
eml_award3$title <- "Methane Production in the Arctic: Under-recognized Cold Season and Upland Tundra - Arctic Methane Sources-UAMS"


# fourth non-NSF Award
eml_award4 <- eml$award()
eml_award4$funderName <- "NOAA Center for Earth System Sciences and Remote Sensing Technologies"
eml_award4$awardNumber <- "NA16SEC4810008"
eml_award4$title <- "Cooperative Agreement Grant"

other_awards <- list(eml_award, eml_award_t, eml_award2, eml_award3, eml_award4)

doc$dataset$project$award <- c(nsf_awards, other_awards)

eml_validate(doc)



## -- Add Physicals -- ##
# If more than one file in dataset:
# Note! If you have a mix of dataTables and otherEntities you will need to modify this code
# Get list of all pids and associated file names
all_pids <- get_package(d1c@mn, packageId, file_names = TRUE)
all_pids <- reorder_pids(all_pids$data, doc) #lines up pids w/correct file

# for loop to assign physicals for each file
for (i in 1:length(all_pids)){
  doc$dataset$otherEntity[[i]]$physical <- pid_to_eml_physical(d1c@mn, all_pids[i])
}

eml_validate(doc)



## -- Convert otherEntities to dataTables for tabular data -- ##
doc <- eml_otherEntity_to_dataTable(doc, 1:3,
                                    validate_eml = F)


# Validate the document. If returns FALSE, ask for help.
eml_validate(doc)