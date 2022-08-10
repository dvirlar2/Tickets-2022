# Uploading ISO metadata to DRP


# load libraries
library(dataone)
  # run auth token in console from DRP 


# load the data one client workspace
cn <- CNode("PROD")

mn <- getMNode(cn, 'urn:node:DRP')

d1c <- D1Client(cn, mn)


# set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")



## -- create package with PANGAEA-CALM metadata -- ##
# create new data package
dp <- new("DataPackage")

# add metadata file
isoFile <- "DRP/CALM_iso19139.xml"

metadataObj <- new("DataObject", format="http://www.isotc211.org/2005/gmd-pangaea",
                   filename=isoFile)
  # For AWS data format: http://www.isotc211.org/2005/gmd 
  # maybe NSIDC format?: http://www.isotc211.org/2005/gmd-noaa
  # for pangea format: http://www.isotc211.org/2005/gmd-pangaea


# add metadata object
dp <- addMember(dp, metadataObj)


# Upload Package
PackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)




## -- create package with PANGAEA-TSP metadata -- ##
# create new data package
dp <- new("DataPackage")

# add metadata file
isoFile <- "DRP/GTN-P_TSP_metadata.txt"

metadataObj <- new("DataObject", format="http://www.isotc211.org/2005/gmd-pangaea",
                   filename=isoFile)
# For AWS data format: http://www.isotc211.org/2005/gmd 
# maybe NSIDC format?: http://www.isotc211.org/2005/gmd-noaa
# for pangea format: http://www.isotc211.org/2005/gmd-pangaea


# add metadata object
dp <- addMember(dp, metadataObj)


# Upload Package
PackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                               accessRules = myAccessRules, quiet=FALSE)
# Error in .local(x, ...) : 
#   Error creating urn:uuid:74ebe7c8-a779-478a-a259-e445a1be3873: Error inserting or updating document: urn:uuid:74ebe7c8-a779-478a-a259-e445a1be3873 since <?xml version="1.0"?><error>Content is not allowed in prolog.</error>