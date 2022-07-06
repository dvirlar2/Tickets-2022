# fix format IDs for spatial vectors muthyala

# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")
packageId <- "resource_map_urn:uuid:2c4e1953-2d90-46c9-bf24-dfc90dd1bda2"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


## -- formatIDs -- ##
# collect all_pids
all_pids <- get_package(d1c@mn, packageId, file_names = TRUE)
all_pids <- reorder_pids(all_pids$data, doc)


# create a list for sysmeta data
sysmeta <- list()

# for loop to fill out sysmeta
for(i in 1:length(all_pids)){
  sysmeta[[i]] <- getSystemMetadata(d1c@mn, all_pids[[i]])
}


# for loop to fix format ID slot
for(i in 1:length(all_pids)){
  sysmeta[[i]]@formatId <- "application/vnd.shp+zip"
}


# update the sysmeta
for(i in 1:length(all_pids)){
  updateSystemMetadata(d1c@mn, all_pids[[i]], sysmeta[[i]])
}
