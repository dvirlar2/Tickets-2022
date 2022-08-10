# Uploading ISO metadata to DRP


# load libraries
library(dataone)
  # run auth token in console from DRP 
d1c <- dataone::D1Client("STAGING", "urn:node:mnTestARCTIC")



# load the data one client workspace
cn <- CNode("PROD")

mn <- getMNode(cn, 'urn:node:DRP')

d1c <- D1Client(cn, mn)


# set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")


## -- create package with NSIDC metadata -- ##
# create new data package
dp <- new("DataPackage")

# add metadata file
isoFile <- "DRP/NSIDC_oai.xml"

metadataObj <- new("DataObject", format="http://www.openarchives.org/OAI/2.0/oai_dc/",
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
