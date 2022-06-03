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
# 
#
# 
# # match your defined attributes to the individual data frames
# att_list_i <- list()
# 
# for (i in 2:length(dat)){
#   # filter from full attribute list the relevant attributes
#   att_list_i[[i]] <- atts_filled %>% 
#     filter(attributeName %in% colnames(dat[[i]]))}
#   #att_list_i[[i]]$id <- uuid::UUIDgenerate(n = nrow(att_list_i[[i]]))
#   
#   # match the order in the original data
#   z <- match(colnames(dat[[i]]), att_list_i[[i]]$attributeName)
#   att_list_i[[i]] <- att_list_i[[i]][z, ]
# }










## ------------------------------------------------------------------------- ##
#read in complete table - manually fixed some stuff and reuploaded
tbl_compl <- read.csv("~/Tickets-2022/attributes_tbl.csv") 
tbl_compl$id <- NULL



# att_test <- set_attributes(attributes = tbl_compl)


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


##### add atts
doc <- read_eml(getObject(d1c@mn, ids$metadata))

# remove site roster from dat_pids
# remove first empty item in dat
dat_pids_real <- tail(dat_pids, 27)


# create your data tables - didn't include 38 because daphne constructed it separately
dts <- list()
for (i in c(1:length(dat_pids_real))){
  dts[[i]] <- pid_to_eml_entity(d1c@mn,
                                dat_pids_real[i],
                                entity_type = "dataTable",
                                attributeList = set_attributes(att_list_i[[i]]))
}


#add datatables 
doc$dataset$dataTable <- dts
#doc <- eml_otherEntity_to_dataTable(doc,
# 28, # which otherEntities you want to convert, for multiple use - 1:5
# validate_eml = F)

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
