# Recover Hongsheng's EML drafts

## -- load libraries -- ##
library(dataone)
library(datapack)
library(uuid)
library(arcticdatautils)
library(EML)

## -- set up -- ##
d1c <- dataone::D1Client("PROD", "urn:node:ARCTIC")

sysmeta1 <- getSystemMetadata(d1c@mn, "urn:uuid:f85695d9-6894-49a2-aa3a-b831118085ae")
path1 <- "~/Scratch/Bi_sysmeta1_eml.xml"

recover_failed_submission(d1c@mn, "urn:uuid:f85695d9-6894-49a2-aa3a-b831118085ae",
                          path1)

# repeat above as necessary
sysmeta0 <- getSystemMetadata(d1c@mn, "urn:uuid:7ac99657-0ed6-421d-9a01-b80cb5ecaf78")
path0 <- "~/Scratch/Bi_sysmeta0_eml.xml"

recover_failed_submission(d1c@mn, "urn:uuid:7ac99657-0ed6-421d-9a01-b80cb5ecaf78",
                          path0)

### ----- ###
sysmeta2 <- getSystemMetadata(d1c@mn, "urn:uuid:65cbdfbb-ab10-439a-9d2d-cbba02e05680")
path2 <- "~/Scratch/Bi_sysmeta2_eml.xml"

recover_failed_submission(d1c@mn, "urn:uuid:65cbdfbb-ab10-439a-9d2d-cbba02e05680",
                          path2)

### ----- ###
sysmeta3 <- getSystemMetadata(d1c@mn, "urn:uuid:da2e28a8-9ebe-4d9e-9cab-6f68a6bc91a8")
path3 <- "~/Scratch/Bi_sysmeta3_eml.xml"

recover_failed_submission(d1c@mn, "urn:uuid:da2e28a8-9ebe-4d9e-9cab-6f68a6bc91a8",
                          path3)

### ----- ###
sysmeta4 <- getSystemMetadata(d1c@mn, "urn:uuid:2143fa3d-786c-4198-93a3-0adb2e65a687")
path4 <- "~/Scratch/Bi_sysmeta4_eml.xml"

recover_failed_submission(d1c@mn, "urn:uuid:2143fa3d-786c-4198-93a3-0adb2e65a687",
                          path4)

### ----- ###
sysmeta5 <- getSystemMetadata(d1c@mn, "urn:uuid:9e9c7489-ea10-4959-b955-268fedb17027")
path5 <- "~/Scratch/Bi_sysmeta5_eml.xml"

recover_failed_submission(d1c@mn, "urn:uuid:9e9c7489-ea10-4959-b955-268fedb17027",
                          path5)

### ----- ###
sysmeta6 <- getSystemMetadata(d1c@mn, "urn:uuid:11ff0165-f2b7-4217-9f7d-970003383cea")
path6 <- "~/Scratch/Bi_sysmeta6_eml.xml"

recover_failed_submission(d1c@mn, "urn:uuid:11ff0165-f2b7-4217-9f7d-970003383cea",
                          path6)

### ----- ###
sysmeta7 <- getSystemMetadata(d1c@mn, "urn:uuid:520625cf-ac8b-4cd7-8b75-cd20a7f0a3de")
path7 <- "~/Scratch/Bi_sysmeta7_eml.xml"

recover_failed_submission(d1c@mn, "urn:uuid:520625cf-ac8b-4cd7-8b75-cd20a7f0a3de",
                          path7)




# read in path0 - path7
EML::read_eml(path7)