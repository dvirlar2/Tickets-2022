# Script Goal: Getting Unique Attributes for Wright Datasets

 
## ------------------------------------------------------------------------- ##
# Load libraries
library(dplyr)
library(arcticdatautils)
library(tidyr)

# Set up
d1c <- D1Client("PROD", "urn:node:ARCTIC")
ids <- get_package(d1c@mn, "resource_map_urn:uuid:39eacd53-0b79-4c61-8c48-b381d7f14f4c",
                   file_names = TRUE)

# Put IDs in order they appear on site
i <- order(names(ids$data))
dat_pids <- ids$data[i]


# set base_url object for cleaner code
base_url <- "https://arcticdata.io/metacat/d1/mn/v2/object/"


# create empty lists
all_cols <- list()
dat <- list()


# read in all the data except site roster (just the first 5 rows for speed)
for (i in 2:length(dat_pids)){
  dat[[i]] <- read.csv(paste0(base_url, dat_pids[i]), nrows = 5, check.names = FALSE)
  all_cols[[i]] <- colnames(dat[[i]])
}


# get a list of unique column names across every file
all_cols_unique <- unlist(all_cols) %>% unique()


## ------------------------------------------------------------------------- ##
# Create an attributeList data frame

# create a data frame with all of the unique columnes
atts_full <- data.frame(attributeName = all_cols_unique)


# Change double underscore to single underscore across all of atts_full
atts_full_rep <- data.frame(lapply(atts_full, function(x) {
  gsub("__", "_", x)
})) 


#create table of sensor codes used by the researchers
tbl_sensor <- bind_cols(code = c("THB", "SMB"),
                        sensor = c("Onset HOBO THB series", "Onset HOBO SMB series"))


#create attribute descriptions
atts_filled <- separate(atts_full_rep, attributeName, 
                        into = c("temp_or_vwc", "type", "depth"), sep = "_", remove = F) %>%
  
  # join atts_filled and tbl_sensor data frames
  left_join(., tbl_sensor, by = c("type" = "code")) %>% 
  
  # create att description based on sensors
  mutate(attributeDefinition  = case_when(
    # VWC description
    temp_or_vwc == "VWC" ~ paste0("Volumetric water content measured using ", sensor, 
                                  " installed at depth ", depth),
    
    # Timestamp description
    temp_or_vwc == "Timestamp" ~ paste0("Dates of measurements in YYYY-MM-DD format"),
    
    # Surface description
    depth == "surf" ~ paste0("Surface temperature measured using ", sensor), 
    
    # Temp description
    TRUE ~  paste0(sensor, " temperature sensor installed at depth ", depth))) %>% 
  
  # add annotations
    # create ID column
  mutate(id = case_when(attributeName == "Timestamp" ~ "timestamp",
                        TRUE ~ paste0(sensor, "_", type, "_", depth)),
        
          # create property label column
         propertyLabel = "contains measurements of type",
         
         # create property URI column
         propertyURI = "http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#containsMeasurementsOfType",
         
         # create value label column 
         valueLabel = case_when(temp_or_vwc == "Timestamp" ~ "date",
                                depth == "surf" ~ "ground surface temperature",
                                TRUE ~ "Ground Temperature"),
         
         # create value URI label column
         valueURI = case_when(temp_or_vwc == "Timestamp" ~ "http://purl.dataone.org/odo/ECSO_00002051",
                              depth == "surf" ~ "http://purl.dataone.org/odo/ECSO_00001527",
                              TRUE ~ "http://purl.dataone.org/odo/ECSO_00001229")) %>%
  
  # create measurementScale column
  mutate(measurementScale = case_when(temp_or_vwc == "Timestamp" ~ "dateTime",
                               temp_or_vwc == "Temp" ~ "interval",
                               TRUE ~ "ratio"),
  
  # create domain
  domain = case_when(temp_or_vwc == "Timestamp" ~ "dateTimeDomain",
                     TRUE ~ "numericDomain"), 
  
  # required for date time measurements
  formatString = case_when(temp_or_vwc == "Timestamp" ~ "YYYY-MM-DD"), 
  
  # add units
  unit = case_when(temp_or_vwc == "Temp" ~ "fahrenheit",
                   temp_or_vwc == "VWC" ~ "meter"),
  
  # number type
  numberType = case_when(temp_or_vwc == "Temp" ~ "real",
                         temp_or_vwc == "VWC" ~ "real")) %>% 
  
  select(-temp_or_vwc, -type, -depth, -sensor)  %>% 
   
  write.csv(., "attributes_tbl.csv", row.names = F)






## ------------------------------------------------------------------------- ##
# read in complete table
tbl_compl <- read.csv("~/Tickets-2022/attributes_tbl.csv") 
tbl_compl$id <- NULL


# match your defined attributes to the individual data frames
att_list_i <- list()

# remove first empty item in dat
dat_real <- tail(dat, 27)


# dat_real colnames have double underscores in the VWC attribute names
# need to remove the double and keep as single
for(i in 1:length(dat_real)){
  colnames(dat_real[[i]]) <- gsub("__", "_", colnames(dat_real[[i]]))
}



for (i in 1:length(dat_real)){
  att_list_i[[i]] <- tbl_compl

  # adding unique id -- necessary for annotations, and eml validation
  att_list_i[[i]]$id <- uuid::UUIDgenerate(n = nrow(att_list_i[[i]]))
  
  z <- match(colnames(dat_real[[i]]), att_list_i[[i]]$attributeName)
  att_list_i[[i]] <- att_list_i[[i]][z, ]
}


# add attributes
doc <- read_eml(getObject(d1c@mn, ids$metadata))


# remove site roster from dat_pids
dat_pids_real <- tail(dat_pids, 27)


# create your data tables
dts <- list()
for (i in c(1:length(dat_pids_real))){
  dts[[i]] <- pid_to_eml_entity(d1c@mn,
                                dat_pids_real[i],
                                entity_type = "dataTable",
                                attributeList = set_attributes(att_list_i[[i]]))
}


#add datatables 
doc$dataset$dataTable <- dts


# need to null the otherEntities with matching names, otherwise EML won't validate
for(i in 2:length(doc$dataset$otherEntity)){
  doc$dataset$otherEntity[[i]] <- NULL
}


# check that doing things manually worked
eml_validate(doc)
  # TRUE

# update document
# installed the develop branch of dataone first
library(dataone)

# Write EML
eml_path <- "~/Scratch/Regional_impacts_of_increasing_fire_frequency.xml"
write_eml(doc, eml_path)


# change access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# load original dp
dp  <- getDataPackage(d1c, identifier = ids$resource_map, lazyLoad=TRUE, quiet=FALSE)

# overwrite existing dp with new xml document, eml_path
dp <- replaceMember(dp, ids$metadata, replacement=eml_path)

# publish updates
newPackageId <- uploadDataPackage(d1c, dp, 
                                  accessRules = myAccessRules,
                                  public=FALSE, quiet=FALSE)



## ------------------------------------------------------------------------- ##
## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# run token in console


# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

# Get the package
packageId <- "resource_map_urn:uuid:1c76689e-054b-4dfa-b035-654d1e9d54e1"

# can't use the develop branch of dataone with this, so using the production version
dp <- dataone::getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

# Get the metadata id
xml <- selectMember(dp, "sysmeta@fileName", ".xml")

# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))


## -- add awards -- ##
doc$dataset$project <- eml_nsf_to_project("1737166")

length(doc$dataset$otherEntity)

length(doc$dataset$dataTable)

names_OE <- vector()
for (i in 1:length(doc$dataset$otherEntity)){
  names_OE[[i]] <- doc$dataset$otherEntity[[i]]$entityName
}

names_DT <- vector()
for (i in 1:length(doc$dataset$dataTable)){
  names_DT[[i]] <- doc$dataset$dataTable[[i]]$entityName
}

(unique(names_DT))

doc$dataset$dataTable[[27]]$entityName

unique(names_OE) == unique(names_DT)



## -------------------------------------------------------------------------- ##
# Tasks: 
# [X] fix awards section
# [X] convert sites roster to data table
# [X] null other entities
# [X] get physical for sites roster
# [X] change lat/long to interval
# [ ] add dataset categorization


## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# run token in console

# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

# Get the package
packageId <- "resource_map_urn:uuid:3c5ae79a-6063-43f5-ba9d-a633fcbda62c"

dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

# Get the metadata id
xml <- selectMember(dp, "sysmeta@fileName", ".xml")

# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))


## -- FAIR Principles -- ##
doc <- eml_add_publisher(doc)
doc <- eml_add_entity_system(doc)


## -- fix/add awards -- ##
doc$dataset$project <- eml_nsf_to_project("1737166")


## -- sites roster OE to DT -- ##
# Find the sites roster index in other entity
which_in_eml(doc$dataset$otherEntity, "entityName", 
             "Melissa_Fire_2022_SitesRoster.csv")
# [1] 14

# Keep just the one you need rather than NULLing
doc$dataset$otherEntity <- doc$dataset$otherEntity[[14]]

# convert sites roster to data table
doc <- eml_otherEntity_to_dataTable(doc, 1, validate_eml = F)

# Add physical to .csv file
roster_pid <- selectMember(dp, name = "sysmeta@fileName", 
                           value = "Melissa_Fire_2022_SitesRoster.csv")
roster_phys <- pid_to_eml_physical(d1c@mn, roster_pid)


# Find the sites roster index in other entity
which_in_eml(doc$dataset$dataTable, "entityName", 
             "Melissa_Fire_2022_SitesRoster.csv")
# [1] 28

doc$dataset$dataTable[[28]]$physical <- roster_phys
eml_validate(doc)
# TRUE


## -- change lat/long measurement type from ratio to interval -- ##
# Change Latitude
doc$dataset$dataTable[[28]]$attributeList$attribute[[10]]$measurementScale <- doc$dataset$dataTable[[28]]$attributeList$attribute[[10]]$measurementScale$interval


doc$dataset$dataTable[[28]]$attributeList$attribute[[10]]$measurementScale$interval$unit$standardUnit <- "degree"


doc$dataset$dataTable[[28]]$attributeList$attribute[[10]]$measurementScale$interval$numericDomain$numberType <- "real"


# Change Latitude
doc$dataset$dataTable[[28]]$attributeList$attribute[[11]]$measurementScale <- doc$dataset$dataTable[[28]]$attributeList$attribute[[11]]$measurementScale$interval


doc$dataset$dataTable[[28]]$attributeList$attribute[[11]]$measurementScale$interval$unit$standardUnit <- "degree"


doc$dataset$dataTable[[28]]$attributeList$attribute[[11]]$measurementScale$interval$numericDomain$numberType <- "real"


## -- categorize dataset -- ##
doc <- eml_categorize_dataset(doc, c("Soil Science", "Forestry"))



## -- update package -- ##
eml_path <- "~/Scratch/Regional_impacts_of_increasing_fire_frequency.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)

## -- add PI access -- ##
# Manually set ORCiD
# Thomas (Colby) Wright
subject <- 'http://orcid.org/0000-0002-2586-6287'

pids <- arcticdatautils::get_package(d1c@mn, packageId)

set_rights_and_access(d1c@mn,
                      pids = c(xml, pids$data, packageId),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))




## ------------------------------------------------------------------------- ##


## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# run token in console


# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "urn:uuid:7b24766b-f305-45ba-ab01-5d504c81aafb"

dp <- dataone::getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)
xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))



## -- entity descriptions -- ##

# index sites Roster
which_in_eml(doc$dataset$dataTable, "entityName", "Melissa_Fire_2022_SitesRoster.csv")
  # 28

# how long is data table
length(doc$dataset$dataTable)
  # 28


t <- vector(length = 27)
t_split <- vector(length = 27)

# for loop for splitting entity names
for(i in 1:27){
  t[i] <- doc$dataset$dataTable[[i]]$entityName
  t_split <- strsplit(t, split = "_|.csv")
}

# assigning entity descriptions based on t_split values
for(i in 1:length(t_split)){
  # dalton fire reference filenames
  if(t_split[[i]][2] == "DHR"){
    doc$dataset$dataTable[[i]]$entityDescription <- paste(
      "Daily data collected in United States at the Dalton Fire Reference site collected between",
      t_split[[i]][6], # day
      month.name[as.numeric(t_split[[i]][5])], # month
      t_split[[i]][4], # year
      "and", 
      t_split[[i]][9], # day
      month.name[as.numeric(t_split[[i]][8])], # month
      t_split[[i]][7] # year
    )
  } else if(t_split[[i]][2] == "DHX" & t_split[[i]][3] == "001"){ # dalton fire 1x
    doc$dataset$dataTable[[i]]$entityDescription <- paste(
      "Daily data collected in United States at the Dalton Fire 1x site collected between",
      t_split[[i]][6], # day
      month.name[as.numeric(t_split[[i]][5])], # month
      t_split[[i]][4], # year
      "and", 
      t_split[[i]][9], # day
      month.name[as.numeric(t_split[[i]][8])], # month
      t_split[[i]][7] # year
    )
  } else if(t_split[[i]][2] == "DHX" & t_split[[i]][3] == "002" ){ # dalton fire 2x
    doc$dataset$dataTable[[i]]$entityDescription <- paste(
      "Daily data collected in United States at the Dalton Fire 2x site collected between",
      t_split[[i]][6], # day
      month.name[as.numeric(t_split[[i]][5])], # month
      t_split[[i]][4], # year
      "and", 
      t_split[[i]][9], # day
      month.name[as.numeric(t_split[[i]][8])], # month
      t_split[[i]][7] # year
    )
  } else if(t_split[[i]][2] == "DHX" & t_split[[i]][3] == "003" ){ # dalton fire 3x
    doc$dataset$dataTable[[i]]$entityDescription <- paste(
      "Daily data collected in United States at the Dalton Fire 3x site collected between",
      t_split[[i]][6], # day
      month.name[as.numeric(t_split[[i]][5])], # month
      t_split[[i]][4], # year
      "and", 
      t_split[[i]][9], # day
      month.name[as.numeric(t_split[[i]][8])], # month
      t_split[[i]][7] # year
    )
  } else if(t_split[[i]][2] == "SHR"){ # Steese Fire Reference
    doc$dataset$dataTable[[i]]$entityDescription <- paste(
      "Daily data collected in United States at the Steese Fire Reference site collected between",
      t_split[[i]][6], # day
      month.name[as.numeric(t_split[[i]][5])], # month
      t_split[[i]][4], # year
      "and", 
      t_split[[i]][9], # day
      month.name[as.numeric(t_split[[i]][8])], # month
      t_split[[i]][7] # year
    )
  } else if(t_split[[i]][2] == "SHX" & t_split[[i]][3] == "001" ){ # Steese 1x
    doc$dataset$dataTable[[i]]$entityDescription <- paste(
      "Daily data collected in United States at the Steese Fire 1x site collected between",
      t_split[[i]][6], # day
      month.name[as.numeric(t_split[[i]][5])], # month
      t_split[[i]][4], # year
      "and", 
      t_split[[i]][9], # day
      month.name[as.numeric(t_split[[i]][8])], # month
      t_split[[i]][7] # year
    )
  } else if(t_split[[i]][2] == "SHX" & t_split[[i]][3] == "002" ){ # Steese 2x
    doc$dataset$dataTable[[i]]$entityDescription <- paste(
      "Daily data collected in United States at the Steese Fire 2x site collected between",
      t_split[[i]][6], # day
      month.name[as.numeric(t_split[[i]][5])], # month
      t_split[[i]][4], # year
      "and", 
      t_split[[i]][9], # day
      month.name[as.numeric(t_split[[i]][8])], # month
      t_split[[i]][7] # year
    )
  } else if(t_split[[i]][2] == "SHX" & t_split[[i]][3] == "003" ){ # Steese 3x
    doc$dataset$dataTable[[i]]$entityDescription <- paste(
      "Daily data collected in United States at the Steese Fire 3x site collected between",
      t_split[[i]][6], # day
      month.name[as.numeric(t_split[[i]][5])], # month
      t_split[[i]][4], # year
      "and", 
      t_split[[i]][9], # day
      month.name[as.numeric(t_split[[i]][8])], # month
      t_split[[i]][7] # year
    )
  }
}


## -- update package -- ##
eml_path <- "~/Scratch/Regional_impacts_of_increasing_fire_frequency.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)




## ------------------------------------------------------------------------- ##
# Jun 27, 2022
# create if statement that changes all fahrenheits to celsius, and int to ratio

## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


## -- general setup -- ##
# run token in console


# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "urn:uuid:67cd5c6a-74da-406c-bfea-d3891a6d1dca"

dp <- dataone::getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)
xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


## -- edit attributes -- ##
# What finds temp in att name?
grepl("Temp", doc$dataset$dataTable[[1]]$attributeList$attribute[[2]]$attributeName)
  # TRUE

# what's the temp unit
doc$dataset$dataTable[[1]]$attributeList$attribute[[2]]$measurementScale$interval

# change temp atts
for(i in 1:length(doc$dataset$dataTable)){
  # create object with attributes
  atts <- doc$dataset$dataTable[[i]]$attributeList$attribute
  
  for(j in 1:length(atts)){
    # change fahr to cels for all temps; and int to ratio
    if(grepl("Temp", atts[[j]]$attributeName)){
      atts[[j]]$measurementScale$interval <- NULL
      atts[[j]]$measurementScale$ratio$unit$standardUnit <- "celsius"
      atts[[j]]$measurementScale$ratio$numericDomain$numberType <- "real"
    }
    attList <- atts
  }
  
  # assign atts back to doc
  doc$dataset$dataTable[[i]]$attributeList$attribute <- attList
}


eml_validate(doc)
# TRUE


# chance VWC atts
for(i in 1:length(doc$dataset$dataTable)){
  # create object with attributes
  atts <- doc$dataset$dataTable[[i]]$attributeList$attribute
  
  for(j in 1:length(atts)){
    # change fahr to cels for all temps; and int to ratio
    if(grepl("VWC", atts[[j]]$attributeName)){
      atts[[j]]$measurementScale$ratio$unit$standardUnit <- "meterCubedPerMeterCubed"
    }
    attList <- atts
  }
  
  # assign atts back to doc
  doc$dataset$dataTable[[i]]$attributeList$attribute <- attList
}

eml_validate(doc)


## -- update package -- ##
eml_path <- "~/Scratch/Regional_impacts_of_increasing_fire_frequency.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)