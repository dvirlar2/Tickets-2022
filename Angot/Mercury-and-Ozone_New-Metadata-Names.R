# Update Angot/Blomquist data with new DOIs and metadata file names

#### Mercury Dataset ###

d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_urn:uuid:50c004a8-93f4-41ef-8fbf-aebc62d71572"
dp <- dataone::getDataPackage(d1c, packageId, lazyLoad = TRUE, quiet = FALSE)

xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- publish update -- ##
eml_path <- "~/Scratch/Gaseous_elemental_mercury_conc.xml"
write_eml(doc, eml_path)

doi <- dataone::generateIdentifier(d1c@mn, "DOI")

dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)


# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

# Update the package
packageId <- uploadDataPackage(d1c, dp, public = TRUE,
                               accessRules = myAccessRules, quiet = FALSE)



### Ozone Dataset ###
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_doi:10.18739/A2N87315K"
dp <- dataone::getDataPackage(d1c, packageId, lazyLoad = TRUE, quiet = FALSE)

xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


## -- publish update -- ##
eml_path <- "~/Scratch/Ambient_air_ozone_mole_fractions.xml"
write_eml(doc, eml_path)

doi <- dataone::generateIdentifier(d1c@mn, "DOI")

dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)


# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org", 
                            permission="changePermission")

# Update the package
packageId <- uploadDataPackage(d1c, dp, public = TRUE,
                               accessRules = myAccessRules, quiet = FALSE)
