# Daphne Virlar-Knight
# May 31, 2022


## -- Tasks -- ## 
# Copy over attributes from one file to another


## -- Set Up -- ##
library(EML)
library(arcticdatautils)
library(datapack)
library(dataone)


# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

# Load target dataset
packageId <- "resource_map_urn:uuid:6c0a1b3d-dc73-4fc3-89ee-755f7253c3fa"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")

doc <- read_eml(getObject(d1c@mn, xml))


# Load source dataset
packageId2 <- "resource_map_doi:10.18739/A2319S405"
dp2  <- getDataPackage(d1c, identifier = packageId2, lazyLoad=TRUE, quiet=FALSE)

xml2 <- selectMember(dp2, name = "sysmeta@fileName", value = ".xml")

doc2 <- read_eml(getObject(d1c@mn, xml2))



## -- copy over excel attributes -- ##
# target: 	LSSL_Geochemistry2021.xlsx
# source: 	LSSL_Geochemistry2020.xlsx

which_in_eml(doc$dataset$otherEntity, "entityName", "d2021_016_0001.cnv")
# target: [3]
which_in_eml(doc2$dataset$dataTable, "entityName", "d2020-79-0001.cnv")
# source: [1]

doc$dataset$otherEntity[[3]]$attributeList 



attributeList <- doc2$dataset$dataTable[[1]]$attributeList

attributeList$attributes$attributeDefinition[[25]] <- "Number of scans per bin"
attributeList$attributes$attributeDefinition[[26]] <- "Flag code for each cast site"
attributeList$attributes$definition[[25]] <- "Number of scans per bin"
attributeList$attributes$definition[[26]] <- "Flag code for each cast site"

doc$dataset$dataTable[[1]]$attributeList <- attributeList