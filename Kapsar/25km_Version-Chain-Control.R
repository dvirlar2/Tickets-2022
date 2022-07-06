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
m_vers <- get_all_versions(d1c@mn, "resource_map_urn:uuid:ba21ed46-4ca8-4e36-9a54-43f168a233ab")
# look at first version on website to get a version of a working resource map
working_rm <- m_vers[1]


# get most recent pids
ids_latest <- get_package(d1c@mn, "resource_map_urn:uuid:ba21ed46-4ca8-4e36-9a54-43f168a233ab")


# get all the working resource map pids
rm_vers <- get_all_versions(d1c@mn, "resource_map_urn:uuid:ba21ed46-4ca8-4e36-9a54-43f168a233ab")


ids_all_data <- get_package(d1c@mn, rm_vers[1])



# check to make sure there are data
dat_pids <- ids$data

rm_pid <- ids_latest$resource_map

# update the most recent resource map with a working version (make SURE the pids are all right)
update_resource_map(d1c@mn, resource_map_pid = rm_pid, 
                    metadata_pid = ids_latest$metadata, 
                    data_pids = ids_all_data$data, 
                    public = FALSE)
