# Broken Resource Map Chains
# Jeanette's Code


## -- load libraries -- ##
library(dataone)
library(datapack)
library(arcticdatautils)
library(EML)

# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

# get all versions of the metadata
m_vers <- get_all_versions(d1c@mn, "resource_map_urn:uuid:728a61f5-4ac3-456c-8436-11e15a220862")
# look at first version on website to get a version of a working resource map
working_rm <- m_vers[1]


# get most recent pids
ids_latest <- get_package(d1c@mn, "resource_map_urn:uuid:728a61f5-4ac3-456c-8436-11e15a220862")


# get all the working resource map pids
rm_vers <- get_all_versions(d1c@mn, "resource_map_urn:uuid:728a61f5-4ac3-456c-8436-11e15a220862")


ids_all_data <- get_package(d1c@mn, rm_vers[1])


rm_pid <- ids_latest$resource_map

# update the most recent resource map with a working version (make SURE the pids are all right)
update_resource_map(d1c@mn, resource_map_pid = rm_pid, 
                    metadata_pid = ids_latest$metadata, 
                    data_pids = ids_all_data$data, 
                    public = FALSE)
