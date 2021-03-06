options(stringsAsFactors = FALSE)
HF_VERSION <- "2016_fine"
source("~/repos/abmianalytics/veghf/veghf-setup.R")

library(dplyr)
lut <- read.csv("~/repos/abmianalytics/lookup/lookup-veg-v6_forMetaData.csv")
lut <- lut %>%
  rename(PreBackfill_Source=preBackfill_Source)
DomInEachNReg <- read.csv("~/repos/abmianalytics/lookup/DomInEachNReg.csv")
upland <- c('AlpineLarch', 'Decid', 'Fir', 'Mixedwood', 'Pine', 'Spruce')
Harvest_Area <-  c("CUTBLOCK","HARVEST-AREA")

## south
xs <- read.csv(file.path(ROOT, "AB_data_v2018", "data", "raw", "hvpoly", "Backfilled100kmtestarea",
    "south-100km-lat-long", "south-converted-attribute-table.csv"))

## restore truncated column headers
xs$Origin_Year <- xs$Origin_Yea
xs$Origin_Yea <- NULL
xs$PreBackfill_Source <- xs$PreBackfil
xs$PreBackfil <- NULL
xs$Moisture_Reg <- xs$Moisture_R
xs$Moisture_R <- NULL
xs$Pct_of_Larch <- xs$Pct_of_Lar
xs$Pct_of_Lar <- NULL
xs$Combined_ChgByCWCS <- Combine_ChgByCWCS(xs)

dfs <- make_vegHF_wide_v6(xs,
    col.label="OBJECTID",
    col.year=2016,
    col.HFyear="YEAR",
    col.HABIT="Combined_ChgByCWCS",
    col.SOIL="Soil_Type_",
    sparse=TRUE, HF_fine=TRUE, wide=FALSE) # use refined classes
dfs$VEGAGEclass <- make_older(dfs$VEGAGEclass, "5")
dfs$VEGHFAGEclass <- make_older(dfs$VEGHFAGEclass, "5")

## north
xn <- read.csv(file.path(ROOT, "AB_data_v2018", "data", "raw", "hvpoly", "Backfilled100kmtestarea",
    "north-100km-lat-long", "north-converted-attribute-table.csv"))

## restore truncated column headers
xn$Origin_Year <- xn$Origin_Yea
xn$Origin_Yea <- NULL
xn$PreBackfill_Source <- xn$PreBackfil
xn$PreBackfil <- NULL
xn$Moisture_Reg <- xn$Moisture_R
xn$Moisture_R <- NULL
xn$Pct_of_Larch <- xn$Pct_of_Lar
xn$Pct_of_Lar <- NULL
xn$Combined_ChgByCWCS <- Combine_ChgByCWCS(xn)

dfn <- make_vegHF_wide_v6(xn,
    col.label="OBJECTID",
    col.year=2016,
    col.HFyear="YEAR",
    col.HABIT="Combined_ChgByCWCS",
    col.SOIL="Soil_Type_",
    sparse=TRUE, HF_fine=TRUE, wide=FALSE) # use refined classes
dfn$VEGAGEclass <- make_older(dfn$VEGAGEclass, "5")
dfn$VEGHFAGEclass <- make_older(dfn$VEGHFAGEclass, "5")

cn <- c("OBJECTID", "NSRNAME", "NRNAME", "LUF_NAME",
    "Shape_Area", "xcoord", "ycoord",
    "PreBackfill_Source", "Moisture_Reg",
    "Pct_of_Larch", "Combined_ChgByCWCS",
    "HF_Year", "SampleYear", "Origin_Year",
    "HFclass", "VEGclass", "AgeRf",
    "CC_ORIGIN_YEAR", "AgeCr", "VEGAGEclass", "VEGHFclass", "VEGHFAGEclass",
    "SOILclass", "SOILHFclass")

## write to an SQLite db
library(DBI)
f <- file.path(ROOT, "AB_data_v2018", "data", "raw", "hvpoly",
    "Backfilled100kmtestarea","polygon-tool-pilot.sqlite")
con <- dbConnect(RSQLite::SQLite(), f)
dbWriteTable(con, "south", dfs[,cn], overwrite = TRUE)
dbWriteTable(con, "north", dfn[,cn], overwrite = TRUE)
dbListTables(con)
dbDisconnect(con)


