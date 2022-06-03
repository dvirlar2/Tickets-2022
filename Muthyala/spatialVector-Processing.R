# Checking attributes of spatial vectors


library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)
library(sf)

d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:de541b63-a2b4-4f6a-a10f-1d484d970a9a"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")
doc <- read_eml(getObject(d1c@mn, xml))

# Get the shapefile pid
streams <- selectMember(dp, name = "sysmeta@fileName", value = "Gauging_Station.zip")

streams_obj <- arcticdatautils::read_zip_shapefile(d1c@mn, streams)

st_geometry(streams_obj)

sf::st_crs(streams_obj)


all_pids <- get_package(d1c@mn, packageId, file_names = TRUE)
all_pids <- reorder_pids(all_pids$data, doc)
length(all_pids)

# keep only the zip pids
all_pids <- c(all_pids[5], all_pids[6], all_pids[7])




for(i in seq_along(vector_entity)){ #length of vector pids
  spatialVector[[i]] <- 
    pid_to_eml_entity(d1c@mn,
                      vector_pids[[i]],
                      entity_type = "spatialVector",
                      entityName = vector_entity[[i]]$entityName,
                      entityDescription = vector_entity[[i]]$entityDescription,
                      attributeList = vector_entity[[i]]$attributeList,
                      #geometry = "Polygon",
                      #spatialReference = list(horizCoordSysName = "GCS_North_American_1983"))
}

