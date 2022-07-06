# Adding PI Access to:
# Density: https://arcticdata.io/catalog/view/doi%3A10.18739%2FA2W08WH6N
# Accumulation: https://arcticdata.io/catalog/view/doi%3A10.18739%2FA28K74X79
# Temperature: https://arcticdata.io/catalog/view/doi%3A10.18739%2FA2DB7VR1P
# Snow depth: https://arcticdata.io/catalog/view/doi%3A10.18739%2FA2222R601



## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)


# ------------------------------ MAIN SUMUP ---------------------------------- # 
## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_doi:10.18739/A2W950P44"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")


## -- set rights & access -- ##
# Setting access to all PIDs associated with package
subject <- 'http://orcid.org/0000-0003-4718-193X'


# get list of current pids
pids <- arcticdatautils::get_package(d1c@mn, packageId)

set_access(d1c@mn,
           pids = c(xml, pids$data, packageId),
           subject = subject,
           permissions = c('read', 'write', 'changePermission'))



# ------------------------------- ACCUMULATION ------------------------------- # 
## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_doi:10.18739/A28K74X79"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")


## -- set rights & access -- ##
# Setting access to all PIDs associated with package
subject <- 'http://orcid.org/0000-0003-4718-193X'


# get list of current pids
pids <- arcticdatautils::get_package(d1c@mn, packageId)

set_access(d1c@mn,
           pids = c(xml, pids$data, packageId),
           subject = subject,
           permissions = c('read', 'write', 'changePermission'))



# ------------------------------- TEMPERATURE ------------------------------- # 
## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_doi:10.18739/A2DB7VR1P"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")


## -- set rights & access -- ##
# Setting access to all PIDs associated with package
subject <- 'http://orcid.org/0000-0003-4718-193X'


# get list of current pids
pids <- arcticdatautils::get_package(d1c@mn, packageId)

set_access(d1c@mn,
           pids = c(xml, pids$data, packageId),
           subject = subject,
           permissions = c('read', 'write', 'changePermission'))



# ------------------------------- SNOW DEPTH ------------------------------- # 
## -- general setup -- ##
# get nodes
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

packageId <- "resource_map_doi:10.18739/A2222R601"
dp <- getDataPackage(d1c, identifier = packageId, lazyLoad=TRUE, quiet=FALSE)

xml <- selectMember(dp, "sysmeta@fileName", ".xml")


## -- set rights & access -- ##
# Setting access to all PIDs associated with package
subject <- 'http://orcid.org/0000-0003-4718-193X'


# get list of current pids
pids <- arcticdatautils::get_package(d1c@mn, packageId)

set_access(d1c@mn,
           pids = c(xml, pids$data, packageId),
           subject = subject,
           permissions = c('read', 'write', 'changePermission'))