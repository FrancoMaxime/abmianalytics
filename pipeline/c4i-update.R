#library(cure4insect)
library(mefa4)
library(intrval)

if (FALSE) {
## fix LUF regions
load("d:/abmi/reports/2017/data/kgrid_areas_by_sector.RData")

load("d:/abmi/AB_data_v2018/data/analysis/kgrid_table_km.Rdata")
all(rownames(kgrid) == rownames(KT))
all(kgrid$LUF_NAME == KT$reg_luf)
KT$reg_luf <- kgrid$LUF_NAME

VER$species <- as.numeric(table(SP$taxon)[rownames(VER)])

save(XY, KT, KA_2012, KA_2014, SP, QT2KT, VER, CF, CFbirds,
    file="d:/abmi/reports/2017/data/kgrid_areas_by_sector.RData")
save(XY, KT, KA_2012, KA_2014, SP, QT2KT, VER, CF, CFbirds,
    file="s:/reports/2017/data/kgrid_areas_by_sector.RData")

}

c4i0 <- new.env()
load("d:/abmi/reports/2017/data/kgrid_areas_by_sector.RData", envir=c4i0)

## same
XY <- c4i0$XY
str(XY)
QT2KT <- c4i0$QT2KT
str(QT2KT)

## lookup
str(c4i0$SP)
ROOT <- "d:/abmi/sppweb2018/c4i/tables"

e1 <- new.env()
e2 <- new.env()
e3 <- new.env()
e4 <- new.env()
e5 <- new.env()
load(file.path(ROOT, paste0("StandardizedOutput-birds.RData")), envir=e1)
load(file.path(ROOT, paste0("StandardizedOutput-vplants.RData")), envir=e2)
load(file.path(ROOT, paste0("StandardizedOutput-mites.RData")), envir=e3)
load(file.path(ROOT, paste0("StandardizedOutput-mosses.RData")), envir=e4)
load(file.path(ROOT, paste0("StandardizedOutput-lichens.RData")), envir=e5)
tmp1 <- e1$Lookup
tmp1$taxon <- "birds"
tmp2 <- e2$Lookup
tmp2$taxon <- "vplants"
tmp3 <- e3$Lookup
tmp3$taxon <- "mites"
tmp4 <- e4$Lookup
tmp4$taxon <- "mosses"
tmp5 <- e5$Lookup
tmp5$taxon <- "lichens"

spt <- rbind(tmp1[,colnames(tmp2)], tmp2,
    tmp3[,colnames(tmp2)], tmp4[,colnames(tmp2)], tmp5[,colnames(tmp2)])
spt <- droplevels(spt[spt$ModelNorth | spt$ModelSouth, ])
rownames(spt) <- spt$SpeciesID
spt$native <- !spt$Nonnative
spt$model_north <- spt$ModelNorth
spt$model_south <- spt$ModelSouth
spt$Species <- as.factor(ifelse(is.na(spt$CommonName),
    as.character(spt$ScientificName), as.character(spt$CommonName)))
spt$habitat_assoc <- c4i0$SP$habitat_assoc[match(rownames(spt), rownames(c4i0$SP))]
spt$model_region <- factor("North and South", levels(c4i0$SP$model_region))
spt$model_region[!spt$model_north] <- "South"
spt$model_region[!spt$model_south] <- "North"
spt <- spt[,colnames(c4i0$SP)]
spt <- droplevels(rbind(spt, c4i0$SP[c4i0$SP$taxon == "mammals",]))
spt$taxon <- as.factor(spt$taxon)

with(c4i0$SP, table(taxon, model_region))
with(spt, table(taxon, model_region))

with(spt, table(taxon, model_region)) - with(c4i0$SP, table(taxon, model_region))
SP <- spt
table(SP$taxon, SP$native)

head(SP)
summary(spt)
str(SP)

## version
VER <- c4i0$VER
VER$version <- 2018
VER$yr_last <- 2017
VER["mammals", "yr_last"] <- c4i0$VER["mammals", "yr_last"]
VER["mosses", "yr_last"] <- 2016
VER$hf <- "2016v3"
VER$veg <- "v6.1"
VER$species <- as.numeric(table(SP$taxon)[rownames(VER)])

c4i0$VER
VER

## regions
KT <- c4i0$KT

load("d:/abmi/AB_data_v2018/data/analysis/kgrid_table_km.Rdata")
all(rownames(kgrid) == rownames(KT))
all(kgrid$LUF_NAME == KT$reg_luf)
if (!all(kgrid$LUF_NAME == KT$reg_luf))
    KT$reg_luf <- kgrid$LUF_NAME

## HF by sector

load("d:/abmi/AB_data_v2018/data/analysis/grid/veg-hf_transitions_v6hf2016v3noDistVeg.Rdata")
stopifnot(all(rownames(KT) == rownames(trVeg)))
tv <- read.csv("~/repos/abmianalytics/lookup/lookup-veg-hf-age-v61.csv")
rownames(tv) <- tv[,1]
tv <- droplevels(tv[!endsWith(rownames(tv), "0"),])
ch2veg$sector <- tv$Sector61[match(ch2veg$cr, rownames(tv))]

KA_2016 <- groupSums(trVeg[,rownames(ch2veg)], 2, ch2veg$sector)
colnames(KA_2016)[colnames(KA_2016) == "Native"] <- "NATIVE"
KA_2016 <- KA_2016[,colnames(c4i0$KA_2014)]
colnames(KA_2016)[colnames(KA_2016) == "NATIVE"] <- "Native"

KA_2016 <- KA_2016 / 10^6

rs <- rowSums(KA_2016)
rs[rs <= 1] <- 1
KA_2016 <- KA_2016 / rs

summary(rowSums(c4i0$KA_2012))
summary(rowSums(c4i0$KA_2014))
summary(rowSums(KA_2016))
sum(c4i0$KA_2012[,-1])/sum(c4i0$KA_2012)
sum(c4i0$KA_2014[,-1])/sum(c4i0$KA_2014)
sum(KA_2016[,-1])/sum(KA_2016)

## CF
load("d:/abmi/reports/2018/misc/DataPortalUpdate.RData")
colnames(c4i0$CF$coef$veg)
summary(c4i0$CF$coef$paspen)
pA <- as.matrix(OUT$pAspen)

Soil <- cbind(as.matrix(OUT$SoilhfSouthNontreed[,-(1:5)]),
    as.matrix(OUT$LinearSouth[,-(1:5)]))
Soil[is.na(Soil)] <- 0
SoilL <- Soil[,startsWith(colnames(Soil), "Lower_")]
SoilU <- Soil[,startsWith(colnames(Soil), "Upper_")]
Soil <- Soil[,!startsWith(colnames(Soil), "Lower_") & !startsWith(colnames(Soil), "Upper_")]
SoilLin <- rbind(
    e1$CoefSouth[, c("SoftLin", "HardLin"),1],
    e2$CoefSouth[, c("SoftLin", "HardLin"),1],
    e3$CoefSouth[, c("SoftLin", "HardLin"),1],
    e4$CoefSouth[, c("SoftLin", "HardLin"),1],
    e5$CoefSouth[, c("SoftLin", "HardLin"),1])
SoilLinL <- rbind(
    e1$LowerSouth[, c("SoftLin", "HardLin")],
    e2$LowerSouth[, c("SoftLin", "HardLin")],
    e3$LowerSouth[, c("SoftLin", "HardLin")],
    e4$LowerSouth[, c("SoftLin", "HardLin")],
    e5$LowerSouth[, c("SoftLin", "HardLin")])
SoilLinU <- rbind(
    e1$UpperSouth[, c("SoftLin", "HardLin")],
    e2$UpperSouth[, c("SoftLin", "HardLin")],
    e3$UpperSouth[, c("SoftLin", "HardLin")],
    e4$UpperSouth[, c("SoftLin", "HardLin")],
    e5$UpperSouth[, c("SoftLin", "HardLin")])
stopifnot(all(rownames(SoilLin) == rownames(SoilLinL)))
stopifnot(all(rownames(SoilLin) == rownames(SoilLinU)))
dot <- endsWith(rownames(SoilLin), ".")
rownames(SoilLin)[dot] <- substr(rownames(SoilLin)[dot], 1, nchar(rownames(SoilLin)[dot])-1)
rownames(SoilLinL) <- rownames(SoilLinU) <- rownames(SoilLin)
Soil <- cbind(Soil, SoilLin[rownames(Soil),])
SoilL <- cbind(SoilL, SoilLinL[rownames(SoilL),])
SoilU <- cbind(SoilU, SoilLinU[rownames(SoilU),])
colnames(Soil)
colnames(c4i0$CF$coef$soil)
colnames(SoilL) <- gsub("Lower_", "", colnames(SoilL))
colnames(SoilL)
colnames(c4i0$CF$lower$soil)
colnames(SoilU) <- gsub("Upper_", "", colnames(SoilU))
colnames(SoilU)
colnames(c4i0$CF$higher$soil)

Veg <- cbind(as.matrix(OUT$VeghfNorth[,-(1:5)]),
    as.matrix(OUT$LinearNorth[,-(1:5)]))
Veg[is.na(Veg)] <- 0
VegL <- Veg[,startsWith(colnames(Veg), "Lower_")]
VegU <- Veg[,startsWith(colnames(Veg), "Upper_")]
Veg <- Veg[,!startsWith(colnames(Veg), "Lower_") & !startsWith(colnames(Veg), "Upper_")]
VegLin <- rbind(
    e1$CoefNorth[, c("SoftLin", "HardLin"),1],
    e2$CoefNorth[, c("SoftLin", "HardLin"),1],
    e3$CoefNorth[, c("SoftLin", "HardLin"),1],
    e4$CoefNorth[, c("SoftLin", "HardLin"),1],
    e5$CoefNorth[, c("SoftLin", "HardLin"),1])
VegLinL <- rbind(
    e1$LowerNorth[, c("SoftLin", "HardLin")],
    e2$LowerNorth[, c("SoftLin", "HardLin")],
    e3$LowerNorth[, c("SoftLin", "HardLin")],
    e4$LowerNorth[, c("SoftLin", "HardLin")],
    e5$LowerNorth[, c("SoftLin", "HardLin")])
VegLinU <- rbind(
    e1$UpperNorth[, c("SoftLin", "HardLin")],
    e2$UpperNorth[, c("SoftLin", "HardLin")],
    e3$UpperNorth[, c("SoftLin", "HardLin")],
    e4$UpperNorth[, c("SoftLin", "HardLin")],
    e5$UpperNorth[, c("SoftLin", "HardLin")])
stopifnot(all(rownames(VegLin) == rownames(VegLinL)))
stopifnot(all(rownames(VegLin) == rownames(VegLinU)))
dot <- endsWith(rownames(VegLin), ".")
rownames(VegLin)[dot] <- substr(rownames(VegLin)[dot], 1, nchar(rownames(VegLin)[dot])-1)
rownames(VegLinL) <- rownames(VegLinU) <- rownames(VegLin)
Veg <- cbind(Veg, VegLin[rownames(Veg),])
VegL <- cbind(VegL, VegLinL[rownames(VegL),])
VegU <- cbind(VegU, VegLinU[rownames(VegU),])
colnames(Veg)
colnames(c4i0$CF$coef$veg)
colnames(VegL) <- gsub("Lower_", "", colnames(VegL))
colnames(VegL)
colnames(c4i0$CF$lower$veg)
colnames(VegU) <- gsub("Upper_", "", colnames(VegU))
colnames(VegU)
colnames(c4i0$CF$higher$veg)

## no mammals included in v2018
CF <- list(
    coef=list(veg=Veg, soil=Soil, paspen=pA),
    lower=list(veg=VegL, soil=SoilL),
    higher=list(veg=VegU, soil=SoilU))
## check pAspen issue
#CF$coef$soil["BairdsSparrow",]
#CF$coef$paspen["BairdsSparrow",1]

## clean up dotted names
tab <- SP
dot <- endsWith(rownames(tab), ".")
dotBad <- rownames(tab)[dot]
dotOK <- substr(dotBad, 1, nchar(dotBad)-1)
data.frame(Bad=dotBad,Good=dotOK, tab$taxon[dot])

for (i in seq_along(dotBad)) {
    levels(SP$SpeciesID)[levels(SP$SpeciesID) == dotBad[i]] <- dotOK[i]
}
fixfun <- function(x) {
    for (i in seq_along(dotBad)) {
        rownames(x)[rownames(x) == dotBad[i]] <- dotOK[i]
    }
    x
}
SP <- fixfun(SP)
CF$coef$veg <- fixfun(CF$coef$veg)
CF$coef$soil <- fixfun(CF$coef$soil)
CF$coef$paspen <- fixfun(CF$coef$paspen)
CF$lower$veg <- fixfun(CF$lower$veg)
CF$lower$soil <- fixfun(CF$lower$soil)
CF$higher$veg <- fixfun(CF$higher$veg)
CF$higher$soil <- fixfun(CF$higher$soil)

compare_sets(rownames(SP)[SP$model_south], rownames(Soil))
SP[rownames(SP) %ni% rownames(Soil) & SP$model_south,]

compare_sets(rownames(SP)[SP$model_north], rownames(Veg))
SP[rownames(SP) %ni% rownames(Veg) & SP$model_north,]

## add in the mammal coefs from v2017
SPPms <- rownames(SP[rownames(SP) %ni% rownames(Soil) & SP$model_south,])
ts <- read.csv("~/repos/cure4insect/inst/crosswalk/soil.csv")[,1:2]
ts <- nonDuplicated(ts, v2018, TRUE)[colnames(CF$coef$soil),]
ts[,1] <- as.character(ts[,1])
ts[,2] <- as.character(ts[,2])
ts["Water", "v2017"] <- "Water"
ts2 <- ts[colnames(CF$lower$soil),]
SoilM <- cbind(c4i0$CF$coef$soil, Water=0)[SPPms,ts$v2017]
colnames(SoilM) <- colnames(CF$coef$soil)
SoilML <- cbind(c4i0$CF$lower$soil, Water=0)[SPPms,ts2$v2017]
colnames(SoilML) <- colnames(CF$lower$soil)
SoilMU <- cbind(c4i0$CF$higher$soil, Water=0)[SPPms,ts2$v2017]
colnames(SoilMU) <- colnames(CF$higher$soil)

pAm <- c4i0$CF$coef$paspen[SPPms,,drop=FALSE]

SPPmn <- rownames(SP[rownames(SP) %ni% rownames(Veg) & SP$model_north,])
tv <- read.csv("~/repos/cure4insect/inst/crosswalk/veg.csv")[,1:2]
tv <- nonDuplicated(tv, v2018, TRUE)[colnames(CF$coef$veg),]
tv[,1] <- as.character(tv[,1])
tv[,2] <- as.character(tv[,2])
tv[c("Water", "Bare"), "v2017"] <- c("Water", "Bare")
tv2 <- tv[colnames(CF$lower$veg),]
VegM <- cbind(c4i0$CF$coef$veg, Bare=0, Water=0)[SPPmn,tv$v2017]
colnames(VegM) <- colnames(CF$coef$veg)
VegML <- cbind(c4i0$CF$lower$veg, Bare=0, Water=0)[SPPmn,tv2$v2017]
colnames(VegML) <- colnames(CF$lower$veg)
VegMU <- cbind(c4i0$CF$higher$veg, Bare=0, Water=0)[SPPmn,tv2$v2017]
colnames(VegMU) <- colnames(CF$higher$veg)

CF$coef$veg <- rbind(CF$coef$veg, VegM)
CF$coef$soil <- rbind(CF$coef$soil, SoilM)
CF$coef$paspen <- rbind(CF$coef$paspen, pAm)
CF$lower$veg <- rbind(CF$lower$veg, VegML)
CF$lower$soil <- rbind(CF$lower$soil, SoilML)
CF$higher$veg <- rbind(CF$higher$veg, VegMU)
CF$higher$soil <- rbind(CF$higher$soil, SoilMU)

str(CF)

compare_sets(rownames(SP)[SP$model_south], rownames(CF$coef$soil))
compare_sets(rownames(SP)[SP$model_north], rownames(CF$coef$veg))

## CFbirds

names(c4i0)

SPPn <- rownames(SP)[SP$taxon=="birds" & SP$model_north]
SPPs <- rownames(SP)[SP$taxon=="birds" & SP$model_south]

rownames(e1$CoefNorthMarginal) <- e1$Lookup$SpeciesID[match(rownames(e1$CoefNorthMarginal), e1$Lookup$Code)]
rownames(e1$CoefNorthJoint) <- e1$Lookup$SpeciesID[match(rownames(e1$CoefNorthJoint), e1$Lookup$Code)]
rownames(e1$CoefSouthMarginal) <- e1$Lookup$SpeciesID[match(rownames(e1$CoefSouthMarginal), e1$Lookup$Code)]
rownames(e1$CoefSouthJoint) <- e1$Lookup$SpeciesID[match(rownames(e1$CoefSouthJoint), e1$Lookup$Code)]

compare_sets(colnames(CF$lower$veg), colnames(e1$CoefNorthMarginal))
aa=e1$CoefNorthMarginal[SPPn,colnames(CF$lower$veg)]

pAm <- sapply(e1$CoefSouthBootlistARU, function(z) z[1,"pAspen"])
pAj <- sapply(e1$CoefSouthBootlistSpace, function(z) z[1,"pAspen"])
names(pAm) <- names(pAj) <- e1$Lookup$SpeciesID[match(names(pAm), e1$Lookup$Code)]

CFbirds <- list(
    marginal=list(
        veg=log(e1$CoefNorthMarginal[SPPn,colnames(CF$lower$veg)]),
        soil=log(e1$CoefSouthMarginal[SPPs,colnames(CF$lower$soil)]),
        paspen=cbind(pAspen=pAm[SPPs])
    ),
    joint=list(
        veg=log(e1$CoefNorthJoint[SPPn,colnames(CF$lower$veg)]),
        soil=log(e1$CoefSouthJoint[SPPs,colnames(CF$lower$soil)]),
        paspen=cbind(pAspen=pAj[SPPs])
    )
)
str(c4i0$CFbirds)
str(CFbirds)
colnames(c4i0$CFbirds[[1]][[1]])
colnames(CFbirds[[1]][[1]])
colnames(c4i0$CFbirds[[1]][[2]])
colnames(CFbirds[[1]][[2]])

sapply(c(CFbirds$marginal, CFbirds$joint), range, na.rm=TRUE)

## address JOING SoftLin in the south

x <- CFbirds$joint$soil
xm <- apply(x[,!(colnames(x) %in% c("HardLin", "SoftLin"))], 1, max, na.rm=TRUE)
xl <- apply(x[,(colnames(x) %in% c("HardLin", "SoftLin"))], 1, max, na.rm=TRUE)

plot(xm, xl)
abline(0,1)
text(xm, xl, ifelse(xl-xm > 5, rownames(x), ""), cex=0.6)

x[xl - xm > 5, c("HardLin")] <- xm[xl - xm > 5]
#x[, c("HardLin")] <- (-Inf)
x[xl - xm > 5, c("SoftLin")] <- xm[xl - xm > 5]
CFbirds$joint$soil <- x

x <- CFbirds$joint$veg

es <- c("WhiteSpruce_0-10", "Pine_0-10", "Deciduous_0-10", "Mixedwood_0-10",
    "BlackSpruce_0-10", "CCWhiteSpruce_0-10", "CCPine_0-10", "CCDeciduous_0-10",
    "CCMixedwood_0-10", "Shrub", "Grass")
xm <- apply(x[,(colnames(x) %in% es)], 1, max, na.rm=TRUE)
xl <- apply(x[,(colnames(x) %in% c("HardLin", "SoftLin"))], 1, max, na.rm=TRUE)

plot(xm, xl)
abline(0,1)
text(xm, xl, ifelse(xl-xm > 5, rownames(x), ""), cex=0.6)

x[xl - xm > 5, c("HardLin")] <- xm[xl - xm > 5]
#x[, c("HardLin")] <- (-Inf)
x[xl - xm > 5, c("SoftLin")] <- xm[xl - xm > 5]

CFbirds$joint$veg <- x

## final tweaks

table(SP$habitat_assoc, useNA="a")
SP$habitat_assoc[is.na(SP$habitat_assoc)] <- "NotAssessed"

## save
save(XY, KT, KA_2016, SP, QT2KT, VER, CF, CFbirds,
    file="d:/abmi/reports/2018/data/kgrid_areas_by_sector.RData")
write.csv(spt, row.names=FALSE, file="d:/abmi/reports/2018/data/species-info.csv")

#write.csv(spt, row.names=FALSE, file="s:/reports/2018/data/species-info.csv")
#save(XY, KT, KA_2016, SP, QT2KT, VER, CF, # CFbirds,
#    file="s:/reports/2018/data/kgrid_areas_by_sector.RData")

## update mammal coefs

library(mefa4)
library(sp)
library(readxl)
load("d:/abmi/reports/2018/data/kgrid_areas_by_sector.RData")
mm <- list(
    coef_veg=read_xlsx("d:/abmi/sppweb2018/snow-tracking/mammals.xlsx", "N"),
    coef_soil=read_xlsx("d:/abmi/sppweb2018/snow-tracking/mammals.xlsx", "S"),
    coef_paspen=read_xlsx("d:/abmi/sppweb2018/snow-tracking/mammals.xlsx", "SA"),
    lower_veg=read_xlsx("d:/abmi/sppweb2018/snow-tracking/mammals.xlsx", "NL"),
    lower_soil=read_xlsx("d:/abmi/sppweb2018/snow-tracking/mammals.xlsx", "SL"),
    higher_veg=read_xlsx("d:/abmi/sppweb2018/snow-tracking/mammals.xlsx", "NU"),
    higher_soil=read_xlsx("d:/abmi/sppweb2018/snow-tracking/mammals.xlsx", "SU"))
for (i in 1:length(mm)) {
    mm[[i]] <- as.data.frame(mm[[i]])
    rownames(mm[[i]]) <- mm[[i]][,1]
    mm[[i]] <- as.matrix(mm[[i]][,-1,drop=FALSE])
}


sn <- rownames(SP[SP$taxon=="mammals" & SP$model_north,])
ss <- rownames(SP[SP$taxon=="mammals" & SP$model_south,])

CF$coef$veg[sn,] <- mm$coef_veg[sn,colnames(CF$coef$veg)]
CF$coef$soil[ss,] <- mm$coef_soil[ss,colnames(CF$coef$soil)]
CF$coef$paspen[ss,] <- mm$coef_paspen[ss,colnames(CF$coef$paspen)]
CF$lower$veg[sn,] <- mm$lower_veg[sn,colnames(CF$lower$veg)]
CF$lower$soil[ss,] <- mm$lower_soil[ss,colnames(CF$lower$soil)]
CF$higher$veg[sn,] <- mm$higher_veg[sn,colnames(CF$higher$veg)]
CF$higher$soil[ss,] <- mm$higher_soil[ss,colnames(CF$higher$soil)]

save(XY, KT, KA_2016, SP, QT2KT, VER, CF, CFbirds,
    file="d:/abmi/reports/2018/data/kgrid_areas_by_sector.RData")

## calculate spclim raster for /spclim

library(mefa4)
library(raster)
source("~/repos/abmianalytics/birds/00-functions.R")
ROOT <- "d:/abmi/AB_data_v2018/data/analysis/birds" # change this bit
#ROOT <- "~/GoogleWork/tmp"

en <- new.env()
load(file.path(ROOT, "data", "ab-birds-north-2018-12-07.RData"), envir=en)
es <- new.env()
load(file.path(ROOT, "data", "ab-birds-south-2018-12-07.RData"), envir=es)
Xn <- get_model_matrix(en$DAT, en$mods)
Xs <- get_model_matrix(es$DAT, es$mods)

cfs <- list(
    spclim=c("pWater_KM",
        "pWater2_KM", "xPET", "xMAT", "xAHM", "xFFP", "xMAP", "xMWMT",
        "xMCMT", "xY", "xX", "xY2", "xX2", "xFFP:xMAP", "xMAP:xPET", "xAHM:xMAT", "xX:xY"))

## kgrid
load("d:/abmi/AB_data_v2018/data/analysis/kgrid_table_km.Rdata")
kgrid$useN <- !(kgrid$NRNAME %in% c("Grassland", "Parkland") | kgrid$NSRNAME == "Dry Mixedwood")
kgrid$useN[kgrid$NSRNAME == "Dry Mixedwood" & kgrid$POINT_Y > 56.7] <- TRUE
kgrid$useS <- kgrid$NRNAME == "Grassland"
kgrid$X <- kgrid$POINT_X
kgrid$Y <- kgrid$POINT_Y

xclim <- data.frame(
    transform_clim(kgrid),
    pAspen=kgrid$pAspen,
    pWater_KM=kgrid$pWater,
    pWater2_KM=kgrid$pWater^2)
## this has pAspen for the south, otherwise all the same
Xclim <- model.matrix(as.formula(paste0("~-1+", paste(cfs$spclim, collapse="+"))), xclim)
colnames(Xclim) <- fix_names(colnames(Xclim))

rt <- raster(system.file("extdata/AB_1km_mask.tif", package="cure4insect"))

make_raster <- function(value, rc, rt)
{
    value <- as.numeric(value)
    r <- as.matrix(Xtab(value ~ Row + Col, rc))
    r[is.na(as.matrix(rt))] <- NA
    raster(x=r, template=rt)
}

## birds
SPP <- rownames(SP)[SP$taxon == "birds"]
AOU <- as.character(e1$Lookup[SPP,"Code"])

for (i in 1:length(AOU)) {
    spp <- AOU[i]
    cat(spp, "\n");flush.console()

    TYPE <- "C" # combo
    if (SP[SPP[i], "model_south"] && !SP[SPP[i], "model_north"])
        TYPE <- "S"
    if (!SP[SPP[i], "model_south"] && SP[SPP[i], "model_north"])
        TYPE <- "N"

    if (TYPE != "N") {
        ests <- e1$CoefSouthBootlistSpace[[spp]][1,cfs$spclim]
        musClim <- drop(Xclim[,cfs$spclim] %*% ests[cfs$spclim])
        rsoil <- make_raster(musClim, kgrid, rt)
    } else {
        rsoil <- NULL
    }

    if (TYPE != "S") {
        estn <- e1$CoefNorthBootlistSpace[[spp]][1,cfs$spclim]
        munClim <- drop(Xclim[,cfs$spclim] %*% estn[cfs$spclim])
        rveg <- make_raster(munClim, kgrid, rt)
    } else {
        rveg <- NULL
    }

    save(rveg, rsoil, file=paste0("d:/abmi/reports/2018/results/birds/spclim/",
        SPP[i], ".RData"))

}


cn <- colnames(e2$SpclimNorth)
compare_sets(cn, colnames(kgrid))
kgrid$Intercept <- 1
kgrid$Lat <- kgrid$POINT_Y
kgrid$Long <- kgrid$POINT_X
kgrid$Lat2 <- kgrid$Lat^2
kgrid$Long2 <- kgrid$Long^2
kgrid$LatLong <- kgrid$Lat*kgrid$Long
kgrid$MAPPET <- kgrid$MAP*kgrid$PET
kgrid$MATAHM <- kgrid$MAT*kgrid$AHM
kgrid$MAPFFP <- kgrid$MAP*kgrid$FFP
kgrid$MAT2 <- kgrid$MAT^2
kgrid$MWMT2 <- kgrid$MWMT^2
setdiff(cn, colnames(kgrid))
Xclim <- as.matrix(kgrid[,cn])

tx <- "vplants"
for (tx in c("vplants", "mites", "mosses", "lichens")) {
    ee <- switch(tx,
        "vplants"=e2,
        "mites"=e3,
        "mosses"=e4,
        "lichens"=e5)
    SPP <- rownames(SP)[SP$taxon == tx]
    for (spp in SPP) {
        cat(tx, spp, "\n");flush.console()

        TYPE <- "C" # combo
        if (SP[spp, "model_south"] && !SP[spp, "model_north"])
            TYPE <- "S"
        if (!SP[spp, "model_south"] && SP[spp, "model_north"])
            TYPE <- "N"

        if (TYPE != "N") {
            ests <- ee$SpclimSouth[spp,,1]
            ests <- ests[names(ests) != "pAspen"]
            musClim <- drop(Xclim[,names(ests)] %*% ests)
            rsoil <- make_raster(musClim, kgrid, rt)
        } else {
            rsoil <- NULL
        }

        if (TYPE != "S") {
            estn <- ee$SpclimNorth[spp,,1]
            munClim <- drop(Xclim[,names(estn)] %*% estn)
            rveg <- make_raster(munClim, kgrid, rt)
        } else {
            rveg <- NULL
        }

        save(rveg, rsoil, file=paste0("d:/abmi/reports/2018/results/", tx, "/spclim/",
            spp, ".RData"))

    }
}


library(readxl)
load("d:/abmi/reports/2018/data/kgrid_areas_by_sector.RData")
Cn <- as.data.frame(read_xlsx("d:/abmi/sppweb2018/snow-tracking/mammals.xlsx", "NC"))
rownames(Cn) <- Cn[,1]
Cn <- as.matrix(Cn[,-1])
Cs <- as.data.frame(read_xlsx("d:/abmi/sppweb2018/snow-tracking/mammals.xlsx", "SC"))
rownames(Cs) <- Cs[,1]
Cs <- as.matrix(Cs[,-1])

cn <- colnames(Cn)
compare_sets(cn, colnames(kgrid))
kgrid$Intercept <- 1
kgrid$V1 <- 1
kgrid$V2 <- 1
kgrid$Lat <- kgrid$POINT_Y
kgrid$Long <- kgrid$POINT_X
kgrid$Lat2 <- kgrid$Lat^2
kgrid$Long2 <- kgrid$Long^2
kgrid$LatLong <- kgrid$Lat*kgrid$Long
kgrid$MAPPET <- kgrid$MAP*kgrid$PET
kgrid$MATAHM <- kgrid$MAT*kgrid$AHM
kgrid$MAPFFP <- kgrid$MAP*kgrid$FFP
kgrid$MAT2 <- kgrid$MAT*abs(kgrid$MAT) # only mammals!!!
kgrid$MWMT2 <- kgrid$MWMT^2
setdiff(cn, colnames(kgrid))
Xclim <- as.matrix(kgrid[,cn])

tx <- "mammals"
SPP <- rownames(SP)[SP$taxon == tx]
for (spp in SPP) {
    cat(tx, spp, "\n");flush.console()

    TYPE <- "C" # combo
    if (SP[spp, "model_south"] && !SP[spp, "model_north"])
        TYPE <- "S"
    if (!SP[spp, "model_south"] && SP[spp, "model_north"])
        TYPE <- "N"

    if (TYPE != "N") {
        ests <- Cs[spp,]
        ests <- ests[names(ests) != "pAspen"]
        musClim <- drop(Xclim[,names(ests)] %*% ests)
        rsoil <- make_raster(musClim, kgrid, rt)
    } else {
        rsoil <- NULL
    }

    if (TYPE != "S") {
        estn <- Cn[spp,]
        munClim <- drop(Xclim[,names(estn)] %*% estn)
        rveg <- make_raster(munClim, kgrid, rt)
    } else {
        rveg <- NULL
    }

    save(rveg, rsoil, file=paste0("d:/abmi/reports/2018/results/", tx, "/spclim/",
        spp, ".RData"))

}



## rename files
fl <- list.files("s:/Result from Ermias_2018/", recursive=TRUE, full.names=TRUE)
fl <- fl[endsWith(fl, "..RData")]
length(fl)
fl2 <- paste0(substr(fl, 1, nchar(fl)-7), ".RData")
file.rename(fl, fl2)

## /sector files

library(cure4insect)
load_common_data()
SP <- get_species_table()

load("d:/abmi/AB_data_v2018/data/analysis/kgrid_table_km.Rdata")
load("d:/abmi/reports/2018/data/kgrid_areas_by_sector.RData")
kgrid$Sonly <- rownames(kgrid) %in% get_all_id("south")
kgrid$Nonly <- rownames(kgrid) %in% get_all_id("north")

load("s:/R km2 grid current and backfilled processed SOUTH.Rdata")
rownames(km2) <- km2$LinkID
kgrid$Sx <- rownames(kgrid) %in% rownames(km2)
table(kgrid$Sonly, kgrid$Sx)
kgrid$SxS <- interaction(kgrid$Sonly, kgrid$Sx)
levels(kgrid$SxS) <- c("Out", "Ponly", "Eonly", "OK")
by(kgrid$pSoil, kgrid$SxS, mean)

str(KT)

#tx <- "vplants"
#tx <- "mammals"
for (tx in c("mites", "vplants", "mosses", "lichens")) {

    dirin <- paste0("s:/Result from Ermias_2018/", tx, "/combined/Sector effects/Sector abundance summary/")
    dirin2 <- paste0("s:/Result from Ermias_2018/", tx, "/combined/Km2 summaries/")

    SPP <- rownames(SP)[SP$taxon == tx]
    #SPP <- gsub(".RData", "", list.files(dirin))
    #spp <- SPP[1]
    for (spp in SPP) {
        TYPE <- "C"
        if (SP[spp,"model_north"] && !SP[spp,"model_south"])
            TYPE <- "N"
        if (!SP[spp,"model_north"] && SP[spp,"model_south"])
            TYPE <- "S"
        cat(tx, spp, TYPE, "\n")
        flush.console()

        ee <- new.env()
        load(paste0(dirin, spp, ".RData"), envir=ee)
        SA.Curr <- as.matrix(ee$SA.curr[,colnames(KA_2016)])
        SA.Ref <- as.matrix(ee$SA.ref[,colnames(KA_2016)])
        SA.Curr <- SA.Curr[match(rownames(kgrid), rownames(SA.Curr)),]
        SA.Ref <- SA.Ref[match(rownames(kgrid), rownames(SA.Ref)),]

        ee2 <- new.env()
        load(paste0(dirin2, spp, ".RData"), envir=ee2)
        Totals <- ee2$RefCurr
        rownames(Totals) <- Totals[,1]
        Totals <- as.matrix(Totals[,-1])
        Totals <- Totals[match(rownames(kgrid), rownames(Totals)),]
        rownames(Totals) <- rownames(kgrid)

        #summary(Totals[kgrid$SxS,])
        #summary(SA.Curr[kgrid$SxS,])

        if (TYPE == "S") {
            SA.Curr <- SA.Curr[kgrid$Sonly,]
            SA.Ref <- SA.Ref[kgrid$Sonly,]
            Totals <- Totals[kgrid$Sonly,]
        }
        if (TYPE == "N") {
            SA.Curr <- SA.Curr[kgrid$Nonly,]
            SA.Ref <- SA.Ref[kgrid$Nonly,]
            Totals <- Totals[kgrid$Nonly,]
        }
        SA.Curr[is.na(SA.Curr)] <- 0
        SA.Ref[is.na(SA.Ref)] <- 0
        Totals[is.na(Totals)] <- 0

        save(SA.Curr, SA.Ref, Totals, file=paste0("d:/abmi/reports/2018/results/", tx, "/sector/",
            spp, ".RData"))
    }
}


## birds
SPP <- rownames(SP)[SP$taxon == "birds"]
AOU <- as.character(e1$Lookup[SPP,"Code"])

for (i in 1:length(AOU)) {
    spp <- AOU[i]
    cat(spp, "\n");flush.console()

    TYPE <- "C" # combo
    if (SP[SPP[i], "model_south"] && !SP[SPP[i], "model_north"])
        TYPE <- "S"
    if (!SP[SPP[i], "model_south"] && SP[SPP[i], "model_north"])
        TYPE <- "N"

    if (TYPE != "N") {
        ests <- e1$CoefSouthBootlistSpace[[spp]][1,cfs$spclim]
        musClim <- drop(Xclim[,cfs$spclim] %*% ests[cfs$spclim])
        rsoil <- make_raster(musClim, kgrid, rt)
    } else {
        rsoil <- NULL
    }

    if (TYPE != "S") {
        estn <- e1$CoefNorthBootlistSpace[[spp]][1,cfs$spclim]
        munClim <- drop(Xclim[,cfs$spclim] %*% estn[cfs$spclim])
        rveg <- make_raster(munClim, kgrid, rt)
    } else {
        rveg <- NULL
    }

    save(rveg, rsoil, file=paste0("d:/abmi/reports/2018/results/birds/spclim/",
        SPP[i], ".RData"))

}






load("d:/abmi/sppweb2018/c4i/tables/lookup-birds.RData")
tax <- droplevels(Lookup[Lookup$ModelNorth | Lookup$ModelSouth,])
rownames(tax) <- tax$Code
SPP <- as.character(tax$SpeciesID)
AOU <- rownames(tax)
CN <- c("Native", "Misc", "Agriculture", "Forestry", "RuralUrban", "Energy", "Transportation")

for (i in 1:length(AOU)) {
    spp <- AOU[i]
    cat(spp, "\n");flush.console()

    ee <- new.env()
    load(paste0("d:/abmi/AB_data_v2018/data/analysis/birds/pred/2019-04-01/", spp, ".RData"), envir=ee)
    SA.Curr <- as.matrix(ee$Curr[,CN])
    SA.Ref <- as.matrix(ee$Ref[,CN])

    save(SA.Curr, SA.Ref, file=paste0("d:/abmi/reports/2018/results/birds/sector/",
        SPP[i], ".RData"))

}


## compare species lists

library(cure4insect)
set_options(path = "s:/reports")
set_options(version = 2017)
load_common_data()
SP1 <- get_species_table()
clear_common_data()
set_options(version = 2018)
load_common_data()
SP2 <- get_species_table()

spp <- intersect(rownames(SP2), rownames(SP1))
tab <- SP2[spp,]
sppNew <- setdiff(rownames(SP2), rownames(SP1))
tabNew <- SP2[sppNew,]
sppOld <- setdiff(rownames(SP1), rownames(SP2))
tabOld <- SP1[sppOld,]

table(tab$taxon)
table(tabNew$taxon)
table(tabOld$taxon)

tabNew[tabNew$taxon=="birds",]
tabOld[tabOld$taxon=="birds",]

## use package to do sector effects updates

devtools::install_github("ABbiodiversity/cure4insect@v2018")
library(cure4insect)
set_options(path = "s:/reports")
set_options(version = 2018)
#clear_common_data()
load_common_data()


KT <- cure4insect:::.c4if$KT
KT$N <- KT$reg_nr != "Grassland" & KT$reg_nr != "Rocky Mountain" &
    KT$reg_nr != "Parkland" & KT$reg_nsr != "Dry Mixedwood"
KT$S <- KT$reg_nr == "Grassland" | KT$reg_nr == "Parkland" |
    KT$reg_nsr == "Dry Mixedwood"


ID <- rownames(KT)[KT$N]
Spp <- get_all_species()
subset_common_data(id=ID, species=Spp)
xxn <- report_all(cores=8)
resn <- do.call(rbind, lapply(xxn, flatten))
class(resn) <- c("data.frame", "c4idf")

#zzz <- list()
#for (spp in Spp) {
#    cat(spp, "\n");flush.console()
#    y <- load_species_data(spp)
#    zzz[[spp]] <- calculate_results(y)
#}

ID <- rownames(KT)[KT$S]
subset_common_data(id=ID, species=Spp)
xxs <- report_all(cores=8)
ress <- do.call(rbind, lapply(xxs, flatten))
class(ress) <- c("data.frame", "c4idf")

save(resn, ress, file="d:/abmi/sppweb2018/c4i/tables/sector-effects.RData")


load("d:/abmi/sppweb2018/c4i/tables/sector-effects.RData")

SPP <- rownames(resn)

for (spp in SPP) {
    TYPE <- "C"
    if (resn[spp, "model_north"] && !resn[spp, "model_south"])
        TYPE <- "N"
    if (!resn[spp, "model_north"] && resn[spp, "model_south"])
        TYPE <- "S"
    if (TYPE != "S") {
        png(paste0("d:/abmi/AB_data_v2018/data/analysis/birds/figs/sector/", spp, "-north.png"),
            height=500, width=1500, res=150)
        op <- par(mfrow=c(1,3))
        plot_sector(resn[spp,], "unit")
        plot_sector(resn[spp,], "regional", main="")
        plot_sector(resn[spp,], "underhf", main="")
        par(op)
        dev.off()
    }
    if (TYPE != "S") {
        png(paste0("d:/abmi/AB_data_v2018/data/analysis/birds/figs/sector/", spp, "-south.png"),
            height=500, width=1500, res=150)
        op <- par(mfrow=c(1,3))
        plot_sector(ress[spp,], "unit")
        plot_sector(ress[spp,], "regional", main="")
        plot_sector(ress[spp,], "underhf", main="")
        par(op)
        dev.off()

    }
}

## udating upland/lowland for BMF v2018

load("d:/abmi/reports/2018/data/kgrid_areas_by_sector.RData")
table(SP$habitat_assoc, useNA="a")

x <- read.csv("d:/abmi/AB_data_v2019/custom-reporting-lookup_2020-01-21.csv")
table(x$HabitatAssoc, useNA="a")
SP$tmp <- x$HabitatAssoc[match(SP$SpeciesID, x$SpeciesID)]
table(SP$habitat_assoc, SP$tmp, useNA="a")
SP[is.na(SP$tmp),]
SP$ha <- SP$habitat_assoc
SP$habitat_assoc[] <- "NotAssessed"
SP$habitat_assoc[!is.na(SP$tmp) & SP$tmp == "Lowland"] <- "Lowland"
SP$habitat_assoc[!is.na(SP$tmp) & SP$tmp == "Upland"] <- "Upland"
table(SP$habitat_assoc, SP$tmp, useNA="a")
SP$tmp <- NULL
SP$ha <- NULL
rm(x)
save(list=c("CF", "CFbirds", "KA_2016", "KT", "QT2KT", "SP", "VER", "XY"),
    file="d:/abmi/reports/2018/data/kgrid_areas_by_sector.RData")
write.csv(SP, row.names=FALSE, file="d:/abmi/reports/2018/data/species-info.csv")


