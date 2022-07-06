# How to find attributes of a shapefile within a data submission

## -- read in package data -- ##
# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")
packageId <- "resource_map_urn:uuid:e877a659-bdd4-46dc-abb8-829afe906ecc"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")
doc <- read_eml(getObject(d1c@mn, xml))


## -- read in spatial data -- ##
# Get the pid of the shapefile you want to look at
stream_pid <- selectMember(dp, name = "sysmeta@fileName", value = "Catchment_boundary.zip")

# Read in the spatial file
stream_file <- arcticdatautils::read_zip_shapefile(d1c@mn, stream_pid)



## -- find attribute list -- ##
# You can use either the head() or names() function to look at the attribute list 
head(stream_file)
names(spatial_file)

# Notice that the output of both includes a "geometry" attribute. 
# This is created by the sf package, and is usual for many reasons.
# However, it is not a "true" attribute from the attribute table of the shapefile.
# Therefore, we can and will ignore it. Any other column is fair game though, 
# and should be included in the attribute lists we create.






doc$dataset$spatialVector[[1]]$geometry <- "LineString"
doc$dataset$spatialVector[[2]]$geometry <- "Point"
doc$dataset$spatialVector[[3]]$geometry <- "LineString"

eml_validate(doc)


## -- update package -- ##
eml_path <- "~/Scratch/62_days_of_Supraglacial_streamflow_from.xml"
write_eml(doc, eml_path)

dp <- replaceMember(dp, xml, replacement = eml_path)

myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

newPackageId <- uploadDataPackage(d1c, dp, public = FALSE,
                                  accessRules = myAccessRules, quiet = FALSE)

## -- add PI access -- ##
# Manually set ORCiD
# Rohi Mothyala
subject <- 'http://orcid.org/0000-0002-8350-8226'

pids <- arcticdatautils::get_package(d1c@mn, packageId)

set_rights_and_access(d1c@mn,
                      pids = c(xml, pids$data, packageId),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))
