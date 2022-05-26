# Daphne Virlar-Knight
# May 26, 2022


## -- Tasks -- ## 
# Change xml name and data file name per Byron's request
# Don't forget to issue a new DOI once processing has been completed


## -- Set Up -- ##
library(EML)
library(arcticdatautils)
library(datapack)
library(dataone)


# Set nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

# Get the package
packageId <- "resource_map_doi:10.18739/A2BV79X0C"
dp  <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

# Get the metadata id
xml <- selectMember(dp, name = "sysmeta@fileName", value = ".xml")

# Read in the metadata
doc <- read_eml(getObject(d1c@mn, xml))
