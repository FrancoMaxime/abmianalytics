HF_VERSION <- "2014_coarse" # load 2014 defs
source("~/repos/abmianalytics/veghf/veghf-setup.R")
load(file.path(ROOT, VER, "data", "analysis", "ages-by-nsr.Rdata"))
gis <- read.csv("~/repos/abmianalytics/lookup/sitemetadata.csv")
rownames(gis) <- gis$SITE_ID

## 3 x 7 yearly veg+HF

fl <- c(
    "veg_hf_3x7_1999.csv",
    "veg_hf_3x7_2001.csv",
    "veg_hf_3x7_2002.csv",
    "veg_hf_3x7_2003.csv",
    "veg_hf_3x7_2004.csv",
    "veg_hf_3x7_2005.csv",
    "veg_hf_3x7_2006.csv",
    "veg_hf_3x7_2007.csv",
    "veg_hf_3x7_2008.csv",
    "veg_hf_3x7_2009.csv",
    "veg_hf_3x7_2010.csv",
    "veg_hf_3x7_2011.csv",
    "veg_hf_3x7_2012.csv",
    "veg_hf_3x7_2013.csv",
    "veg_hf_3x7_2014.csv",
    "veg_hf_3x7_2015.csv")
yr <- c(1999, 2001, 2002:2015)

#hfdiff <- list()
#i <- 1
for (i in 1:length(fl)) {
    cat(i, "of", length(fl), "---", fl[i], "\n");flush.console()
    f <- file.path(ROOT, VER, "data", "raw", "veghf", "3x7", fl[i])
    d <- read.csv(f)
    d$inventory_year <- yr[i]
#    hfdiff[[i]] <- setdiff(levels(d$FEATURE_TY), c("", rownames(hflt)))
    save(d, file=file.path(ROOT, VER, "data", "inter", "veghf", "3x7",
        gsub(".csv", ".Rdata", fl[i])))
}
#cat(sort(unique(unlist(hfdiff))), sep="\n")

yearly_vhf <- list()
#i <- 1
for (i in 1:length(fl)) {
    cat(i, "of", length(fl), "---", fl[i], "\n");flush.console()
    load(file=file.path(ROOT, VER, "data", "inter", "veghf", "3x7",
        gsub(".csv", ".Rdata", fl[i])))
    if (!("year" %in% colnames(d)))
        colnames(d)[colnames(d) == "YEAR"] <- "year"
    dd <- make_vegHF_wide_v6(d,
        col.label="ABMI",
        col.year="inventory_year",
        col.HFyear="year",
        col.HABIT="Combined_ChgByCWCS",
        col.SOIL="Soil_Type_1",
        sparse=TRUE,
        HF_fine=FALSE)
    dd$scale <- "3x7 km rectangle around NSF site"
    dd$sample_year <- yr[i]

    dx <- gis[rownames(dd[[1]]),]
    dd2 <- fill_in_0ages_v6(dd, dx$NATURAL_SUBREGIONS, ages_list)

    yearly_vhf[[as.character(yr[i])]] <- dd2
}

#tv <- read.csv("~/repos/abmianalytics/lookup/lookup-veg-hf-age-V6.csv")
#compare_sets(colnames(dd2[[1]]), rownames(tv))

save(yearly_vhf,
    file=file.path(ROOT, VER, "data", "analysis",
    "veg-hf_3x7_v6-fixage0.Rdata"))

## summaries

HF_VERSION <- "2014_coarse" # load 2014 defs
source("~/repos/abmianalytics/veghf/veghf-setup.R")
load(file.path(ROOT, VER, "data", "analysis", "ages-by-nsr.Rdata"))
gis <- read.csv("~/repos/abmianalytics/lookup/sitemetadata.csv")
rownames(gis) <- gis$SITE_ID
gis <- gis[as.character(1:1656),]

load(file.path(ROOT, VER, "data", "analysis",
    "veg-hf_3x7_v6-fixage0.Rdata"))

tv <- read.csv("~/repos/abmianalytics/lookup/lookup-veg-hf-age-v6.csv")

yr <- as.integer(names(yearly_vhf))

veg3x7_current <- list()
veg3x7_reference <- list()
veg3x7_sector <- list()
for (i in as.character(yr)) {
    x <- as.matrix(yearly_vhf[[i]][[1]])[,rownames(tv)]
    x <- 100 * x / rowSums(x)
    veg3x7_current[[i]] <- x[,colnames(x)[!endsWith(colnames(x),"0")]]
    veg3x7_sector[[i]] <- groupSums(x, 2, tv$ETA_UseInAnalysis_Sector)

    x <- as.matrix(yearly_vhf[[i]][[2]])[,rownames(tv)[!tv$IS_HF]]
    x <- 100 * x / rowSums(x)
    veg3x7_reference[[i]] <- x[,colnames(x)[!endsWith(colnames(x),"0")]]
}
stopifnot(all(rownames(veg3x7_sector[[1]])==rownames(gis)))

save(veg3x7_reference, veg3x7_current, gis, veg3x7_sector,
    file=file.path(ROOT, VER, "data", "analysis",
    "veg-hf_3x7_1999-2015-summaries.Rdata"))

for (i in as.character(yr)) {
    write.csv(veg3x7_current[[i]],
        file=file.path(ROOT, VER, "data", "analysis", "3x7tables",
        paste0("3x7table-current-", i, ".csv")))
    write.csv(veg3x7_reference[[i]],
        file=file.path(ROOT, VER, "data", "analysis", "3x7tables",
        paste0("3x7table-reference-", i, ".csv")))
}




yr <- as.integer(names(yearly_vhf))
REG <- gis$NATURAL_REGIONS
hf <- array(NA, c(nlevels(REG)+1, 7+1, length(yr)))
dimnames(hf)[[3]] <- yr
for (i in as.character(yr)) {
    x <- as.matrix(yearly_vhf[[i]][[1]])[,rownames(tv)]
    x <- 100 * x / rowSums(x)
    x <- x[,!is.na(tv$HF)]
    x <- groupSums(x, 2, tv$UseInHFReporting[!is.na(tv$HF)])
    x <- cbind(x, "Total"=rowSums(x))
    x2 <- rbind(groupMeans(x, 1, REG), "Alberta"=colMeans(x))
    hf[,,i] <- x2
}
dimnames(hf)[[1]] <- rownames(x2)
dimnames(hf)[[2]] <- colnames(x2)

save(hf, file="~/Dropbox/www/opencpu/footprintchange/data/hf.rda")


load("~/Dropbox/www/opencpu/footprintchange/data/hf.rda")

dput(table(gis$NATURAL_REGIONS)/nrow(gis))

hfplot <- function (
    region = c("Alberta",
        "Canadian Shield",
        "Boreal",
        "Foothills",
        "Rocky Mountain",
        "Parkland",
        "Grassland"),
    type = c("Total",
        "Human-created Water Bodies",
        "Agriculture",
        "Urban, Rural & Industrial",
        "Mines, Wells & Other Energy Features",
        "Vegetated Linear Industrial Features",
        "Transportation",
        "Forest Harvest")) {
    region <- match.arg(region)
    type <- match.arg(type)
    Year <- c(1999, 2001, 2002:2014)
    Footprint <- hf[region,type,]
    Rate <- diff(range(Footprint)) / diff(range(Year))
    p <- ggplot2::qplot(Year, Footprint,
        ylab=paste(type, "Footprint (%)"),
        main=paste0(region, " (", round(Rate,2), "%/yr)"),
        geom=c("point","line")) + theme_grey(base_size = 18)
	print(p)
	invisible()
}
hfplot("Boreal", "Forest Harvest")
hfplot("Grassland", "Vegetated Linear Industrial Features")

## summary in OSA

load(file.path(ROOT, VER, "data", "analysis",
    "veg-hf_3x7_v6-fixage0.Rdata")) # yearly_vhf
osa <- read.csv(file.path(ROOT, VER, "data", "raw",
    "xy", "osa", "nfi_3regions.csv"))

fosa <- osa$SHORTNAME[match(1:1656, osa$ABMI)]
levels(fosa) <- c(levels(fosa), "OUT")
fosa[is.na(fosa)] <- "OUT"
table(fosa)

compare_sets(hfgroups$HF_GROUP, colnames(aa))
ci0 <- c("BorrowpitsDugoutsSumps",
    "Canals", "CultivationCropPastureBareground", "CutBlocks", "HighDensityLivestockOperation",
    "IndustrialSiteRural", "MineSite", "MunicipalWaterSewage", "OtherDisturbedVegetation",
    "PeatMine", "Pipeline", "RailHardSurface", "RailVegetatedVerge",
    "Reservoirs", "RoadHardSurface", "RoadTrailVegetated", "RoadVegetatedVerge",
    "RuralResidentialIndustrial", "SeismicLine", "TransmissionLine",
    "Urban", "WellSite", "WindGenerationFacility", "CCDecidR", "CCDecid1",
    "CCDecid2", "CCDecid3", "CCDecid4", "CCMixedwoodR", "CCMixedwood1",
    "CCMixedwood2", "CCMixedwood3", "CCMixedwood4", "CCPineR", "CCPine1",
    "CCPine2", "CCPine3", "CCPine4", "CCSpruceR", "CCSpruce1", "CCSpruce2",
    "CCSpruce3", "CCSpruce4")

ci1 <- c("BorrowpitsDugoutsSumps",
    "Canals", "CultivationCropPastureBareground", "CutBlocks", "HighDensityLivestockOperation",
    "IndustrialSiteRural", "MineSite", "MunicipalWaterSewage", "OtherDisturbedVegetation",
    "PeatMine", "Pipeline", "RailHardSurface", "RailVegetatedVerge",
    "Reservoirs", "RoadHardSurface", "RoadTrailVegetated", "RoadVegetatedVerge",
    "RuralResidentialIndustrial", "SeismicLine", "TransmissionLine",
    "Urban", "WellSite", "WindGenerationFacility", "CutBlocks", "CutBlocks",
    "CutBlocks", "CutBlocks", "CutBlocks", "CutBlocks", "CutBlocks",
    "CutBlocks", "CutBlocks", "CutBlocks", "CutBlocks", "CutBlocks",
    "CutBlocks", "CutBlocks", "CutBlocks", "CutBlocks", "CutBlocks", "CutBlocks",
    "CutBlocks", "CutBlocks")
sect <- hfgroups$Sector[match(ci1, hfgroups$HF_GROUP)]

tmp <- do.call(rbind, lapply(names(yearly_vhf), function(z) {
    out <- yearly_vhf[[z]]$veg_current
    out <- as.matrix(groupSums(out, 1, fosa))
    out <- out[rownames(out) != "OUT",]
    out <- rbind(out, "All-OSA"=colSums(out))
    out <- 100 * out / rowSums(out)
    out <- groupSums(out[,ci0], 2, sect)
    data.frame(Year=as.integer(z), Region=rownames(out), out)
    }))

write.csv(tmp, row.names=FALSE,
    file.path(ROOT, VER, "data", "analysis", "veg-hf_3x7_v6_inOSA.csv"))

## summary by nar teg groups

fosa <- gis$NATURAL_REGIONS
levels(fosa) <- c("BoShFh", "BoShFh", "BoShFh", "GrPa", "GrPa", "Rockies")
tmp <- do.call(rbind, lapply(names(yearly_vhf), function(z) {
    out <- yearly_vhf[[z]]$veg_current
    out <- as.matrix(groupSums(out, 1, fosa))
    out <- out[rownames(out) != "OUT",]
    out <- rbind(out, "All-AB"=colSums(out))
    out <- 100 * out / rowSums(out)
    out <- groupSums(out[,ci0], 2, sect)
    data.frame(Year=as.integer(z), Region=rownames(out), out)
    }))

write.csv(tmp, row.names=FALSE,
    file.path(ROOT, VER, "data", "analysis", "veg-hf_3x7_v6_inNRegions.csv"))
