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


## -- create package with AWS metadata -- ##
# create new data package
dp <- new("DataPackage")

# add metadata file
isoFile <- "DRP/AWS_Alaska_Climate_Data_iso19139.xml"

metadataObj <- new("DataObject", format="http://www.isotc211.org/2005/gmd",
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
#   Error creating urn:uuid:fd1e97ac-6b4e-4cac-b21a-2d8571b3101c: Error inserting or updating document: urn:uuid:fd1e97ac-6b4e-4cac-b21a-2d8571b3101c since <?xml version="1.0"?><error>cvc-complex-type.2.4.a: Invalid content was found starting with element '{"http://www.opengis.net/gml":TimePeriod}'. One of '{"http://www.opengis.net/gml/3.2":AbstractTimePrimitive}' is expected.</error>


## -- create package with NSIDC metadata -- ##
# create new data package
dp <- new("DataPackage")

# add metadata file
isoFile <- "DRP/NSIDC_Sea_Ice_Index.xml"

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
#   Error creating urn:uuid:5d583fa4-c43b-4c97-90bb-1ebe097213bd: Error inserting or updating document: urn:uuid:5d583fa4-c43b-4c97-90bb-1ebe097213bd since <?xml version="1.0"?><error>The namespace http://www.openarchives.org/OAI/2.0/ used in the xml object hasn't been registered in the Metacat. Metacat can't validate the object and rejected it. Please contact the operator of the Metacat for regsitering the namespace.</error>


## -- create package with PANGAEA-CALM metadata -- ##
# create new data package
dp <- new("DataPackage")

# add metadata file
isoFile <- "DRP/GTN-P_CALM_metadata.txt"

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
#   Error creating urn:uuid:73ece7d0-a54a-42d3-9503-b3a545ba4132: Error inserting or updating document: urn:uuid:73ece7d0-a54a-42d3-9503-b3a545ba4132 since <?xml version="1.0"?><error>Content is not allowed in prolog.</error>



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