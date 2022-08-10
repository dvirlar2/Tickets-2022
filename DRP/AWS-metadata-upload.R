# Uploading ISO metadata to DRP


# load libraries
library(dataone)
  # run auth token in console from DRP 

# for testing the upload
d1c <- dataone::D1Client("STAGING", "urn:node:mnTestARCTIC")


# for actually running the upload to the DRP
cn <- CNode("PROD")

mn <- getMNode(cn, 'urn:node:DRP')

d1c <- D1Client(cn, mn)


# set access rules
myAccessRules <- data.frame(subject="http://orcid.org/0000-0003-3708-6154",
                            permission="changePermission")
  # using my Orcid for now


## -- create package with AWS metadata -- ##
# create new data package
dp <- new("DataPackage")

# add metadata file
isoFile <- "DRP/AWS_Alaska_Climate_Data_iso19139.xml"

metadataObj <- new("DataObject", format="http://www.isotc211.org/2005/gmd",
                   filename=isoFile, id = "fed1b39e-d57f-4c10-8511-f32d9dc6c0ac")
# For AWS data format: http://www.isotc211.org/2005/gmd 
# maybe NSIDC format?: http://www.isotc211.org/2005/gmd-noaa
# for pangea format: http://www.isotc211.org/2005/gmd-pangaea


# add metadata object
dp <- addMember(dp, metadataObj)


# Upload Package
PackageId <- uploadDataPackage(d1c, dp, public=TRUE,
                               accessRules = myAccessRules, quiet=FALSE)
# Error in .local(x, ...) : 
#   Error creating urn:uuid:fd1e97ac-6b4e-4cac-b21a-2d8571b3101c: Error inserting or updating document: urn:uuid:fd1e97ac-6b4e-4cac-b21a-2d8571b3101c since <?xml version="1.0"?><error>cvc-complex-type.2.4.a: Invalid content was found starting with element '{"http://www.opengis.net/gml":TimePeriod}'. One of '{"http://www.opengis.net/gml/3.2":AbstractTimePrimitive}' is expected.</error>

##
# Fixed the above error by adding '/3.2' to the end of line 4 in the AWS metadata file