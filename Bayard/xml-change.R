d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:987828f6-15bb-4fcb-94cc-ce7a6354617c"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)


xml <- selectMember(dp, "sysmeta@fileName", ".xml")
doc <- read_eml(getObject(d1c@mn, xml))



eml_path <- "~/Scratch/Benthic_macroinfaunal_samples_collected_from_the_SWL_2018.xml"
write_eml(doc, eml_path)

# replace eml 
dp <- replaceMember(dp, xml, replacement = eml_path)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=FALSE,
                                  accessRules = myAccessRules, quiet=FALSE)
