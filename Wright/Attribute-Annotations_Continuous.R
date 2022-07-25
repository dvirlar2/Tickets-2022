# Anurag
# 7/15

# Ticket: [url]
# Dataset: https://arcticdata.io/catalog/view/urn:uuid:27e501c1-5e06-4a68-aed2-e787238ec71f


## -- load libraries -- ##
library(dataone)
library(datapack)
library(arcticdatautils)
library(EML)




## -- read in the metadata -- ##
# Reminder: Get server token, and run it in the console

# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")


# Get the package
packageId <- "resource_map_urn:uuid:88efc233-3594-4bd9-bfad-fe697a2b1fdb"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)



# Get the metadata id
# This works when there is no other xml file in the data submission. If there is
# more than one xml file, the line below will assign multiple pids to the xml object
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")

# If there is more than one xml file, run the following line instead.
# metadataId <- selectMember(dp, name="sysmeta@formatId", value="https://eml.ecoinformatics.org/eml-2.2.0")


# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))


#Adding annotations
for (i in seq_along(doc$dataset$dataTable)){
  for (j in seq_along(doc$dataset$dataTable[[i]]$attributeList$attribute)){
    if (j == 1){
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$id <- paste(
        "entity", doc$dataset$dataTable[[i]]$entityName, "attribute",
        doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$attributeName, sep="_")
      
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$propertyURI <- list(
        label = "contains measurements of type",
        propertyURI = "http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#containsMeasurementsOfType")
      
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$valueURI <- list(
        label = "date",
        valueURI = "http://purl.dataone.org/odo/ECSO_00002051")
      
    } else if (grepl('_surf$',doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$attributeName)){
      
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$id <- uuid::UUIDgenerate()
      
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$propertyURI <- list(
        label = "contains measurements of type",
        propertyURI = "http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#containsMeasurementsOfType")
      
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$valueURI <- list(
        label = "ground surface temperature",
        valueURI = "http://purl.dataone.org/odo/ECSO_00001527")
    } else if (grepl('\\dm$',doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$attributeName)){
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$id <- uuid::UUIDgenerate()
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$propertyURI <- list(label = "contains measurements of type",
                                                                                             propertyURI = "http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#containsMeasurementsOfType")
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$valueURI <- list(label = "Ground Temperature",
                                                                                          valueURI = "http://purl.dataone.org/odo/ECSO_00001229")
    } else if (grepl('air$',doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$attributeName)){
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$id <- paste("entity", doc$dataset$dataTable[[i]]$entityName, "attribute", doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$attributeName, sep="_")
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$propertyURI <- list(label = "contains measurements of type",
                                                                                             propertyURI = "http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#containsMeasurementsOfType")
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$valueURI <- list(label = "Air Temperature",
                                                                                          valueURI = "http://purl.dataone.org/odo/ECSO_00001225")
    } else if (grepl('^VWC',doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$attributeName)){
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$id <- paste("entity", doc$dataset$dataTable[[i]]$entityName, "attribute", doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$attributeName, sep="_")
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$propertyURI <- list(label = "contains measurements of type",
                                                                                             propertyURI = "http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#containsMeasurementsOfType")
      doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$annotation$valueURI <- list(label = "volumetric water content",
                                                                                          valueURI = "http://purl.dataone.org/odo/ECSO_00001662")
    }
  }
}


#Add missing value codes
for (i in seq_along(doc$dataset$dataTable)){
  for (j in seq_along(doc$dataset$dataTable[[i]]$attributeList$attribute)){
    doc$dataset$dataTable[[i]]$attributeList$attribute[[j]]$missingValueCode <- eml$missingValueCode(code = "NaN",
                                                                                                     codeExplanation = "Removed or missing data are denoted with NaN values")
  }
}




## -- add discipline categorization -- ##
# Disciplines can be found here: https://bioportal.bioontology.org/ontologies/ADCAD/?p=classes&conceptid=root

# Remember to check with the team to make sure people agree with your selection(s)!
doc <- eml_categorize_dataset(doc, "Soil Science")

# one last validation check
eml_validate(doc)



## -- set rights & access -- ##
# There's a bug that that occasionally strips a researcher of access to their
# datasets when we update their data submissions. To get around this, we've decided
# to manually set the rights and access at the end of all scripts until the
# bug has been fixed. Let Jeanette or Daphne know if you have any issues!
# Manually set ORCiD
subject <- 'http://orcid.org/0000-0002-2586-6287'


# Get data pids
ids <- getIdentifiers(dp)

# set rights
set_rights_and_access(d1c@mn,
                      pids = c(ids, packageId),
                      subject = subject,
                      permissions = c('read', 'write', 'changePermission'))

## -- update your package -- ##
# I recommend creating a Scratch folder in your Home directory where all your
# updated xml documents will live. This keeps things uncluttered, and helps
# prevent your from accidentally pushing the .xml file to GitHub (DONT do that)
eml_path <- "~/Scratch/Thermal_State_of_Permafrost_in_North_America_Continuous.xml"
write_eml(doc, eml_path)

# Replace existing metadata
# Syntax: replaceMember(dp, item to be replaced, replacement file)
dp <- replaceMember(dp, xml, replacement = eml_path)


# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Update the package
packageId <- uploadDataPackage(d1c, dp, public = FALSE,
                               accessRules = myAccessRules, quiet = FALSE)




## -- publish package with DOI -- ##
# Once you have received final approval from the PI, you can run the following code.
# Code has been commented out to prevent accidental publishing of datasets
# -- add distribution -- #
id <- generateIdentifier(d1c@mn, "doi")
doc <- eml_add_distribution(doc, id)


# -- publish the package -- ##
# write EML
eml_path <- "~/Your_Path_Here.xml"
write_eml(doc, eml_path)


# replace eml and add doi
dp <- replaceMember(dp, xml, replacement=eml_path, newId=doi)

# Set access rules
myAccessRules <- data.frame(subject="CN=arctic-data-admins,DC=dataone,DC=org",
                            permission="changePermission")

# Publish package with DOI
newPackageId <- uploadDataPackage(d1c, dp, public=TRUE,
                                  accessRules = myAccessRules, quiet=FALSE)