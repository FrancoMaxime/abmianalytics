library(mefa4)
library(pbapply)
library(RColorBrewer)

ROOT <- "c:/p/AB_data_v2015/out/birds"

#setwd("c:/p/AB_data_v2015/out/birds/results")
#fl <- list.files()
#fl2 <- gsub("birds_bam-", "birds_abmi-", fl)
#for (i in 1:length(fl))
#    if (fl[i] != fl2[i])
#        file.rename(fl[i], fl2[i])

level <- 0.9

up <- function() {
    source("~/repos/bragging/R/glm_skeleton.R")
    source("~/repos/abmianalytics/R/results_functions.R")
    source("~/repos/bamanalytics/R/makingsense_functions.R")
    source("~/repos/abmianalytics/R/wrsi_functions.R")
#    source("~/repos/abmianalytics/R/results_functions1.R")
#    source("~/repos/abmianalytics/R/results_functions2.R")
    invisible(NULL)
}
up()

e <- new.env()
load(file.path(ROOT, "data", "data-full-withrevisit.Rdata"), envir=e)
dat <- e$DAT
dat <- dat[dat$useOK,]
yy <- e$YY[rownames(dat),]
tax <- droplevels(e$TAX[colnames(yy),])
pveghf <- e$pveghf[rownames(dat),]
pveghf <- data.frame(as.matrix(pveghf))
pveghf$Open <- pveghf$GrassHerb + pveghf$Shrub
pveghf <- as.matrix(pveghf[,c("Decid", "Mixwood", "Conif", "Pine", "BSpr", "Larch",
    "Open", "Wetland", "Cult", "UrbInd", "HardLin", "SoftLin")])
colnames(pveghf) <- c("Deciduous", "Mixedwood", "White Spruce", "Pine",
    "Black Spruce", "Larch",
    "Open", "Wet", "Cultivated", "Urban/Industrial", "Hard Linear", "Soft Linear")
psoilhf <- as.matrix(e$psoilhf[rownames(dat),c("Productive", "Clay",
    "Saline", "RapidDrain", "Cult", "UrbInd")])
colnames(psoilhf) <- c("Productive", "Clay",
    "Saline", "Rapid Drain", "Cultivated", "Urban/Industrial")

## singing birds crosstab
if (FALSE) {
    sb <- read.csv("~/repos/bamanalytics/lookup/singing-species.csv")
    rownames(sb) <- sb$Species_ID
    compare_sets(rownames(tax), rownames(sb))
    sb2 <- tax[setdiff(rownames(tax), rownames(sb)),c("Species_ID", "English_Name",
        "Family_Sci")]
    sb2 <- sb2[rownames(sb2) != "NONE",]
    sb2$Singing_birds <- NA
    sb3 <- rbind(sb[intersect(rownames(tax), rownames(sb)),], sb2)
    write.csv(sb3, row.names=F, file="Bird-spp.csv")
}


en <- new.env()
load(file.path(ROOT, "data", "data-useok-north.Rdata"), envir=en)
xnn <- en$DAT
modsn <- en$mods
yyn0 <- en$YY

es <- new.env()
load(file.path(ROOT, "data", "data-useok-south.Rdata"), envir=es)
xns <- es$DAT
modss <- es$mods
yys0 <- es$YY
rm(e, en, es)

yyn <- yy[rownames(yyn0),]
yys <- yy[rownames(yys0),]

## model for species
fl <- list.files(file.path(ROOT, "results"))
fln <- fl[grep("-north_", fl)]
fln <- sub("birds_abmi-north_", "", fln)
fln <- sub(".Rdata", "", fln)
fls <- fl[grep("-south_", fl)]
fls <- sub("birds_abmi-south_", "", fls)
fls <- sub(".Rdata", "", fls)

tax$ndet <- colSums(yy>0)
tax$modelN <- rownames(tax) %in% fln
tax$modelS <- rownames(tax) %in% fls
#tax$ndet_n <- colSums(yyn>0)[match(colnames(yy), colnames(yyn))]
#tax$ndet_s <- colSums(yys>0)[match(colnames(yy), colnames(yys))]
tax$ndet_n <- colSums(yyn>0)[match(rownames(tax), colnames(yyn))]
tax$ndet_s <- colSums(yys>0)[match(rownames(tax), colnames(yys))]
tax$ndet_n[is.na(tax$ndet_n)] <- 0
tax$ndet_s[is.na(tax$ndet_s)] <- 0

yy <- yy[,tax$ndet > 0]
tax <- droplevels(tax[colnames(yy),])
tax$file <- nameAlnum(as.character(tax$English_Name), "mixed", "")

pveghf <- pveghf[rownames(yyn),]
psoilhf <- psoilhf[rownames(yys),]

## terms and design matrices
nTerms <- getTerms(modsn, "list")
sTerms <- getTerms(modss, "list")
Xnn <- model.matrix(getTerms(modsn, "formula"), xnn)
colnames(Xnn) <- fixNames(colnames(Xnn))
Xns <- model.matrix(getTerms(modss, "formula"), xns)
colnames(Xns) <- fixNames(colnames(Xns))

stage_hab_n <- 5
stage_hab_s <- 2

## tax placeholders for all the output
tax$ndet_ns <- pmax(tax$ndet_n, tax$ndet_s)
tax$map_det <- tax$ndet_ns > 0
tax$useavail_north <- tax$ndet_n > 3
tax$useavail_south <- tax$ndet_s > 3
tax$trend_north <- tax$modelN
tax$trend_south <- tax$modelS
tax$veghf_north <- tax$modelN
tax$soilhf_nontreed_south <- tax$modelS
tax$soilhf_treed_south <- tax$modelS
tax$linear_north <- tax$modelN
tax$linear_south <- tax$modelS
tax$surroundinghf_north <- tax$modelN
tax$surroundinghf_south <- tax$modelS

yy <- yy[,colnames(yy) != "NONE"]
yys <- yys[,colnames(yys) != "NONE"]
yyn <- yyn[,colnames(yyn) != "NONE"]
tax <- droplevels(tax[colnames(yy),])

## species lookup table for web
slt <- data.frame(sppid=tax$file,
    species=tax$English_Name,
    scinam=tax$Scientific_Name,
    tax[,c("ndet","modelN","modelS","ndet_n","ndet_s", "ndet_ns")])
slt$map.det <- tax$map_det
slt$veghf.north <- tax$modelN & tax$ndet_n > 99
slt$soilhf.south <- tax$modelS & tax$ndet_s > 49
slt$map.pred <- slt$veghf.north | slt$soilhf.south
slt$useavail.north=tax$useavail_north & !slt$veghf.north
slt$useavail.south=tax$useavail_south & !slt$soilhf.south
slt$AOU <- rownames(slt)
slt <- slt[slt$map.det,]

gl <- read.csv("~/repos/abmianalytics/lookup/vertebrate-guilds.csv")
intersect(gl$AOU.Code, rownames(slt))
slt[setdiff(rownames(slt), gl$AOU.Code),1:3]

slt$oldforest <- gl$Forest.Types.Old[match(rownames(slt), gl$AOU.Code)]
slt$oldforest[is.na(slt$oldforest)] <- 0
slt$oldforest[slt$oldforest > 0] <- 1
#write.csv(slt, row.names=FALSE, file="~/repos/abmispecies/_data/birds.csv")
sb <- read.csv("~/repos/abmianalytics/lookup/singing-species-alberta.csv")
slt$singing <- sb$Singing_birds[match(rownames(slt), sb$Species_ID)]
write.csv(slt, file=file.path(ROOT, "birds-lookup.csv"))

#slt <- read.csv("~/repos/abmispecies/_data/birds.csv")
rownames(slt) <- slt$AOU

## spp specific output

spp <- "BTNW"

## useavail-north
## table: useavail-north

res_useavail_north <- list()
for (spp in rownames(tax)) {
if (tax[spp, "useavail_north"]) {
    cat(spp, "\n");flush.console()
    keep <- rowSums(pveghf) > 0
    yyy <- yyn[keep, spp]
    hhh <- pveghf[keep,]
    NAM <- as.character(tax[spp, "English_Name"])
    NDAT <- sum(yyn[,spp] > 0)
    fname <- file.path(ROOT, "figs", "useavail-north",
        paste0(as.character(tax[spp, "file"]), ".png"))
    png(file=fname, width=480, height=480)
    tmp <- plot_wrsi(yyy, hhh, south=FALSE)
    mtext(paste0(NAM, " (n = ", NDAT, " detections)"), adj=0, line=2,
        side=3, cex=1.2, col="grey40", las=1)
    dev.off()
    res_useavail_north[[spp]] <- tmp
}
}
wrsi_n <- t(sapply(res_useavail_north, "[[", "WRSI"))
colnames(wrsi_n) <- paste0(nameAlnum(rownames(res_useavail_north[[1]]), "mixed", ""),
    "_WRSI")
rwrsi_n <- t(sapply(res_useavail_north, "[[", "rWRSI"))
colnames(rwrsi_n) <- paste0(nameAlnum(rownames(res_useavail_north[[1]]), "mixed", ""),
    "_rWRSI")
wrsi_n <- data.frame(tax[rownames(wrsi_n), c("English_Name","Scientific_Name")],
    cbind(wrsi_n, rwrsi_n))
write.csv(wrsi_n, file=file.path(ROOT, "figs", "useavail-north.csv"))

## useavail-south
## table: useavail-south

res_useavail_south <- list()
for (spp in rownames(tax)) {
if (tax[spp, "useavail_south"]) {
    cat(spp, "\n");flush.console()
    keep <- rowSums(psoilhf) > 0
    yyy <- yys[keep, spp]
    hhh <- psoilhf[keep,]
    NAM <- as.character(tax[spp, "English_Name"])
    NDAT <- sum(yys[,spp] > 0)
    fname <- file.path(ROOT, "figs", "useavail-south",
        paste0(as.character(tax[spp, "file"]), ".png"))
	png(file=fname, width=480, height=480)
    plot_wrsi(yyy, hhh, south=TRUE)
    mtext(paste0(NAM, " (n = ", NDAT, " detections)"), adj=0, line=2,
        side=3, cex=1.2, col="grey40", las=1)
    dev.off()
    res_useavail_south[[spp]] <- tmp
}
}
wrsi_s <- t(sapply(res_useavail_south, "[[", "WRSI"))
colnames(wrsi_s) <- paste0(nameAlnum(rownames(res_useavail_south[[1]]), "mixed", ""),
    "_WRSI")
rwrsi_s <- t(sapply(res_useavail_south, "[[", "rWRSI"))
colnames(rwrsi_s) <- paste0(nameAlnum(rownames(res_useavail_south[[1]]), "mixed", ""),
    "_WRSI")
wrsi_s <- data.frame(tax[rownames(wrsi_s), c("English_Name","Scientific_Name")],
    cbind(wrsi_s, rwrsi_s))
write.csv(wrsi_s, file=file.path(ROOT, "figs", "useavail-south.csv"))

## map-det

load(file.path("c:/p/AB_data_v2015/out", "kgrid", "kgrid_table.Rdata"))
col1 <- c("#C8FBC8","#C8E6FA","#F5E6F5","#FFDCEC","#FFE6CD","#FFF1D2")[match(kgrid$NRNAME,
    c("Boreal","Foothills","Rocky Mountain","Canadian Shield","Parkland","Grassland"))]
## analysis regions
if (FALSE) {
col1 <- c("green","green","grey","green","brown","yellow")[match(kgrid$NRNAME,
    c("Boreal","Foothills","Rocky Mountain","Canadian Shield","Parkland","Grassland"))]
col1[kgrid$NSRNAME == "Dry Mixedwood"] <- "brown"
png(file="analysis-regions.png", width=600, height=1000)
plot(kgrid$X, kgrid$Y, pch=15, cex=0.2, col=col1, axes=FALSE, ann=FALSE)
dev.off()
}

library(raster)
library(sp)
library(rgdal)
city <-data.frame(x = -c(114,113,112,111,117,118)-c(5,30,49,23,8,48)/60,
    y = c(51,53,49,56,58,55)+c(3,33,42,44,31,10)/60)
rownames(city) <- c("Calgary","Edmonton","Lethbridge","Fort McMurray",
    "High Level","Grande Prairie")
coordinates(city) <- ~ x + y
proj4string(city) <- CRS(paste0("+proj=longlat +datum=WGS84 ",
    "+ellps=WGS84 +towgs84=0,0,0"))
city <- as.data.frame(spTransform(city, CRS(paste0("+proj=tmerc +lat_0=0 +lon_0=-115 +k=0.9992 ",
    "+x_0=500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"))))
xyw <- as.matrix(kgrid[kgrid$pWater >= 0.99,c("X","Y")])
blank <- matrix(0, 0, 2)
for (spp in rownames(tax)) {
if (tax[spp, "map_det"]) {
    cat(spp, "\n");flush.console()
    if (spp %in% colnames(yyn)) {
        xy0n <- as.matrix(xnn[yyn[,spp] == 0,c("X","Y")])
        xy1n <- as.matrix(xnn[yyn[,spp] > 0,c("X","Y")])
    } else {
        xy0n <- blank
        xy1n <- blank
    }
    if (spp %in% colnames(yys)) {
        xy0s <- as.matrix(xns[yys[,spp] == 0,c("X","Y")])
        xy1s <- as.matrix(xns[yys[,spp] > 0,c("X","Y")])
    } else {
        xy0s <- blank
        xy1s <- blank
    }
    xy0 <- rbind(xy0n, xy0s)
    xy1 <- rbind(xy1n, xy1s)
    NAM <- as.character(tax[spp, "English_Name"])
    NDAT <- length(unique(rownames(xy1)))
    fname <- file.path(ROOT, "figs", "map-det",
        paste0(as.character(tax[spp, "file"]), ".png"))
	png(file=fname, width=600, height=1000)
    postscript(paste0("e:/peter/", as.character(tax[spp, "file"]), "-detections.eps"),
        horizontal = FALSE, onefile = FALSE, paper = "special",
        width=6, height=10)

    plot(kgrid$X, kgrid$Y, pch=15, cex=0.2, col=col1, axes=FALSE, ann=FALSE)
    points(xyw, pch=15, cex=0.2, col=rgb(0.3,0.45,0.9))
    points(xy0, pch="+", cex=0.5, col="red3")
    #points(xy0, pch=19, cex=0.5, col="red3")
    points(xy1, pch=16, cex=1.6, col="red4")
    mtext(paste0(NAM, " (n = ", NDAT, " detections)"), line=2,
        side=3, adj=0.5, cex=1.4, col="grey40")
    points(city, pch=18, col="grey10")
    text(city, rownames(city), cex=0.8, adj=-0.1, col="grey10")

	dev.off()
}
}

## calculating # occurrences
xnn$lxn <- interaction(xnn$LUF_NAME, xnn$NSRNAME, drop=TRUE, sep="_")
xns$lxn <- interaction(xns$LUF_NAME, xns$NSRNAME, drop=TRUE, sep="_")
y01 <- list()
for (spp in rownames(tax)) {
if (tax[spp, "map_det"]) {
    cat(spp, "\n");flush.console()
    y01[[spp]] <- table(lxn=c(as.character(xnn$lxn), as.character(xns$lxn)),
        det=c(ifelse(yyn[,spp]>0, 1, 0), ifelse(yys[,spp]>0, 1, 0)))[,"1"]
}
}
y01 <- do.call(cbind, y01)
colnames(y01) <- slt[colnames(y01), "sppid"]
tmp <- strsplit(rownames(y01), "_")
y01d <- data.frame(LUFxNSR=rownames(y01),
    LUF=sapply(tmp, "[[", 1),
    NSR=sapply(tmp, "[[", 2),
    y01)
write.csv(y01d, row.names=FALSE, file=file.path(ROOT, "birds-number-of-occurrences.csv"))

## veghf-north
## linear-north
## table: veghf-north

list_df <- list()
for (spp in rownames(tax)) {
    cat(spp, "\n");flush.console()
    df_n <- df_s <- 0
    if (tax[spp, "veghf_north"]) {
        resn <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-north_", spp, ".Rdata")))
        estn6 <- getEst(resn, stage=6, na.out=FALSE, Xnn)
        df_n <- sum(colSums(abs(estn6)) == 0)
    }
    if (tax[spp, "soilhf_treed_south"]) {
        ress <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-south_", spp, ".Rdata")))
        ests_hab <- getEst(ress, stage=3, na.out=FALSE, Xns)
        df_s <- sum(colSums(abs(ests_hab)) == 0)
    }
    list_df[[spp]] <- c(N=df_n, S=df_s)
}
list_df <- do.call(rbind, list_df)
summary(list_df)


for (spp in rownames(tax)) {
    cat(spp, "\n");flush.console()
    NAM <- as.character(tax[spp, "English_Name"])
if (tax[spp, "veghf_north"]) {
    resn <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-north_", spp, ".Rdata")))
    estn6 <- getEst(resn, stage=6, na.out=FALSE, Xnn)
    fname <- file.path(ROOT, "coefs",
        paste0(as.character(tax[spp, "file"]), "_Stage6_coefs.csv"))
    write.csv(estn6, row.names=FALSE, file=fname)
}
}

res_veghf <- list()
for (spp in rownames(tax)) {
    cat(spp, "\n");flush.console()
    NAM <- as.character(tax[spp, "English_Name"])
if (tax[spp, "veghf_north"]) {
    resn <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-north_", spp, ".Rdata")))
    estn_hab <- getEst(resn, stage=stage_hab_n, na.out=FALSE, Xnn)
    prn <- pred_veghf(estn_hab, Xnn)
    res_veghf[[spp]] <- prn
    NDAT <- sum(yyn[,spp] > 0)
    ## veghf
    fname <- file.path(ROOT, "figs", "veghf-north",
        paste0(as.character(tax[spp, "file"]), ".png"))
    png(file=fname,width=1500,height=700)
	fig_veghf(prn, paste0(NAM, " (n = ", NDAT, " detections)"))
	dev.off()
	## linear
    fname <- file.path(ROOT, "figs", "linear-north",
        paste0(as.character(tax[spp, "file"]), ".png"))
	png(file=fname,width=350,height=400)
    fig_linear(attr(prn, "linear"), paste0(NAM, "\nNorth (n = ", NDAT, " det.)"))
    dev.off()
}
}

f1 <- function(x) {
    rr <- attr(x, "linear")[-1]
    names(rr) <- c("SoftLinear", "SoftLinear.LCL", "SoftLinear.UCL",
        "HardLinear", "HardLinear.LCL", "HardLinear.UCL")
    x <- x[rownames(x) != "Burn",c(2,3,4)]
    rownames(x) <- gsub(" ", "", rownames(x))
    xx <- t(x)
    dim(xx) <- NULL
    names(xx) <- paste0(rep(rownames(x), each=3), c("", ".LCL", ".UCL"))
    c(xx, rr)
}
vhf <- t(sapply(res_veghf, f1))
vhf2 <- data.frame(tax[rownames(vhf), c("English_Name","Scientific_Name")],
    vhf)
vhf2 <- vhf[rownames(slt)[slt$veghf.north],]
write.csv(vhf2, file=file.path(ROOT, "figs", "birds-veghf-north.csv"))

SPP <- rownames(slt)[slt$veghf.north]

vhf2 <- read.csv(file.path(ROOT, "figs", "birds-veghf-north.csv"))
rownames(vhf2) <- vhf2$X
vhf2 <- vhf2[,-(1:3)]

excl <- c(grep(".LCL", colnames(vhf2)), grep(".UCL", colnames(vhf2)))
vhf2 <- as.matrix(vhf2[,-excl])
Max <- apply(vhf2[,1:(ncol(vhf2)-2)], 1, max)
vhf2 <- vhf2 / Max
vhf2[vhf2[,"HardLinear"] > 5,"HardLinear"] <- 5

## soilhf-treed-south
## soilhf-nontreed-south
## linear-south
## table: soilhf-north

res_soilhf <- list()
for (spp in rownames(tax)) {
    cat(spp, "\n");flush.console()
    NAM <- as.character(tax[spp, "English_Name"])
if (tax[spp, "soilhf_treed_south"] | tax[spp, "soilhf_nontreed_south"]) {
    ress <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-south_", spp, ".Rdata")))
    ests_hab <- getEst(ress, stage=stage_hab_s, na.out=FALSE, Xns)
    prs <- pred_soilhf(ests_hab, Xns)
    res_soilhf[[spp]] <- prs
    NDAT <- sum(yys[,spp] > 0)
    YMAX <- max(fig_soilhf_ymax(prs$treed), fig_soilhf_ymax(prs$nontreed))
    ## treed
    fname <- file.path(ROOT, "figs", "soilhf-treed-south",
        paste0(as.character(tax[spp, "file"]), ".png"))
    png(file=fname,width=500,height=450)
	fig_soilhf(prs$treed, paste0(NAM, ", South, Treed (n = ", NDAT, " detections)"),
        ymax=YMAX)
	dev.off()
    ## nontreed
    fname <- file.path(ROOT, "figs", "soilhf-nontreed-south",
        paste0(as.character(tax[spp, "file"]), ".png"))
    png(file=fname,width=500,height=450)
	fig_soilhf(prs$nontreed, paste0(NAM, ", South, Non-treed (n = ", NDAT, " detections)"),
        ymax=YMAX)
	dev.off()
	## linear
    fname <- file.path(ROOT, "figs", "linear-south",
        paste0(as.character(tax[spp, "file"]), ".png"))
	png(file=fname,width=350,height=400)
    fig_linear(prs$linear, paste0(NAM, "\nSouth (n = ", NDAT, " det.)"))
    dev.off()
}
}

f2 <- function(x) {
    rr <- x$linear[-1]
    names(rr) <- c("SoftLinear", "SoftLinear.LCL", "SoftLinear.UCL",
        "HardLinear", "HardLinear.LCL", "HardLinear.UCL")
    x <- x$nontreed
    rownames(x) <- gsub(" ", "", rownames(x))
    xx <- t(x[,2:4])
    dim(xx) <- NULL
    names(xx) <- paste0(rep(rownames(x), each=3), c("", ".LCL", ".UCL"))
    c(xx, rr)
}
soil <- t(sapply(res_soilhf, f2))
soil2 <- data.frame(tax[rownames(soil), c("English_Name","Scientific_Name")],
    soil)
soil2 <- soil2[rownames(slt)[slt$soilhf.south],]
write.csv(soil2, file=file.path(ROOT, "figs", "birds-soilhf-south.csv"))

## climate & surrounding hf tables, climate surface maps

cn <- c("xPET", "xMAT", "xAHM", "xFFP",
    "xMAP", "xMWMT", "xMCMT", "xlat", "xlong", "xlat2", "xlong2",
    "THF_KM", "Lin_KM", "Nonlin_KM", "Succ_KM", "Alien_KM", "Noncult_KM",
    "Cult_KM", "THF2_KM", "Nonlin2_KM", "Succ2_KM", "Alien2_KM",
    "Noncult2_KM")
transform_CLIM <- function(x, ID="PKEY") {
    z <- x[,ID,drop=FALSE]
    z$xlong <- (x$POINT_X - (-113.7)) / 2.15
    z$xlat <- (x$POINT_Y - 53.8) / 2.28
    z$xAHM <- (x$AHM - 0) / 50
    z$xPET <- (x$PET - 0) / 800
    z$xFFP <- (x$FFP - 0) / 130
    z$xMAP <- (x$MAP - 0) / 2200
    z$xMAT <- (x$MAT - 0) / 6
    z$xMCMT <- (x$MCMT - 0) / 25
    z$xMWMT <- (x$MWMT - 0) / 20
    z
}
xclim <- transform_CLIM(kgrid, "Row_Col")
xclim$xlat2 <- xclim$xlat^2
xclim$xlong2 <- xclim$xlong^2
ffTerms <- getTerms(modsn["Space"], "formula", intercept=FALSE)
Xclim <- model.matrix(ffTerms, xclim)
colnames(Xclim) <- fixNames(colnames(Xclim))
excln <- kgrid$NRNAME %in% c("Rocky Mountain", "Grassland")
excls <- rep(TRUE, nrow(kgrid))
excls[kgrid$NRNAME %in% c("Grassland", "Parkland")] <- FALSE
excls[kgrid$NSRNAME %in% c("Dry Mixedwood")] <- FALSE
clim_n <- list()
clim_s <- list()
for (spp in rownames(tax)) {
    cat(spp, "\n");flush.console()
    NAM <- as.character(tax[spp, "English_Name"])
if (tax[spp, "surroundinghf_north"]) {
    resn <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-north_", spp, ".Rdata")))
    estn_sp <- getEst(resn, stage=stage_hab_n + 2, na.out=FALSE, Xnn)
    sp_n <- colMeans(estn_sp[,cn])
    clim_n[[spp]] <- sp_n

    fname <- file.path(ROOT, "figs", "climate-north",
        paste0(as.character(tax[spp, "file"]), ".png"))
    ## quick and dirty
    pr <- exp(drop(Xclim %*% colMeans(estn_sp[,colnames(Xclim)])))
    ## bootstrap based and correct
#    pr <- rowMeans(exp(apply(estn_sp[,colnames(Xclim)], 1, function(z) drop(Xclim %*% z))))
    q <- quantile(pr, 0.99)
    pr[pr > q] <- q
    pr <- pr/max(pr)
    pr[excln] <- NA
    qq <- quantile(pr, seq(0.1, 0.9, 0.1), na.rm=TRUE)
    z <- cut(pr, c(-1, unique(qq), 2))
    Col <- rev(terrain.colors(nlevels(z)))
	png(file=fname, width=600, height=1000)

    plot(kgrid$X, kgrid$Y, pch=15, cex=0.2, col=Col[z], axes=FALSE, ann=FALSE)
    points(kgrid$X[excln], kgrid$Y[excln], pch=15, cex=0.2, col="darkgrey")
    mtext(paste0(NAM, ", North"), line=2, side=3, adj=0.5, cex=1.4, col="grey40")
    points(xyw, pch=15, cex=0.2, col=rgb(0.3,0.45,0.9))
    points(city, pch=18, col="grey10")
    text(city, rownames(city), cex=0.8, adj=-0.1, col="grey10")
    legend("bottomleft", col=rev(Col), fill=rev(Col),
        legend=c("High", rep("", length(Col)-2), "Low"), bty="n")

	dev.off()
}
if (tax[spp, "surroundinghf_south"]) {
    ress <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-south_", spp, ".Rdata")))
    ests_sp <- getEst(ress, stage=stage_hab_s + 2, na.out=FALSE, Xns)
    sp_s <- colMeans(ests_sp[,cn])
    clim_s[[spp]] <- sp_s

    fname <- file.path(ROOT, "figs", "climate-south",
        paste0(as.character(tax[spp, "file"]), ".png"))
    ## quick and dirty
    pr <- exp(drop(Xclim %*% colMeans(ests_sp[,colnames(Xclim)])))
    ## bootstrap based and correct
#    pr <- rowMeans(exp(apply(ests_sp[,colnames(Xclim)], 1, function(z) drop(Xclim %*% z))))
    q <- quantile(pr, 0.99)
    pr[pr > q] <- q
    pr <- pr/max(pr)
    pr[excls] <- NA
    qq <- quantile(pr, seq(0.1, 0.9, 0.1), na.rm=TRUE)
    z <- cut(pr, c(-1, unique(qq), 2))
    Col <- rev(terrain.colors(nlevels(z)))
	png(file=fname, width=600, height=1000)

    plot(kgrid$X, kgrid$Y, pch=15, cex=0.2, col=Col[z], axes=FALSE, ann=FALSE)
    points(kgrid$X[excls], kgrid$Y[excls], pch=15, cex=0.2, col="darkgrey")
    mtext(paste0(NAM, ", South"), line=2, side=3, adj=0.5, cex=1.4, col="grey40")
    points(xyw, pch=15, cex=0.2, col=rgb(0.3,0.45,0.9))
    points(city, pch=18, col="grey10")
    text(city, rownames(city), cex=0.8, adj=-0.1, col="grey10")
    legend("bottomleft", col=rev(Col), fill=rev(Col),
        legend=c("High", rep("", length(Col)-2), "Low"), bty="n")

	dev.off()
}
}

clim_N <- data.frame(tax[names(clim_n), c("English_Name","Scientific_Name")],
    do.call(rbind, clim_n))
clim_S <- data.frame(tax[names(clim_s), c("English_Name","Scientific_Name")],
    do.call(rbind, clim_s))
clim_N <- clim_N[rownames(slt)[slt$modelN],]
clim_S <- clim_S[rownames(slt)[slt$modelS],]

write.csv(clim_N, file=file.path(ROOT, "figs", "climatehf-north.csv"))
write.csv(clim_S, file=file.path(ROOT, "figs", "climatehf-south.csv"))


## surroundinghf-north
## surroundinghf-south

for (spp in rownames(tax)) {
    cat(spp, "\n");flush.console()
    NAM <- as.character(tax[spp, "English_Name"])
if (tax[spp, "surroundinghf_north"]) {
    resn <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-north_", spp, ".Rdata")))
    estn_sp <- getEst(resn, stage=stage_hab_n + 2, na.out=FALSE, Xnn)
    fname <- file.path(ROOT, "figs", "surroundinghf-north",
        paste0(as.character(tax[spp, "file"]), ".png"))
    png(file=fname, width=7.5, height=5.7, units="in", res=300)
    op <- par(mai=c(0.9,1,0.2,0.3))
    fig_hf_noremn(estn_sp, Xnn, LAB=paste0(NAM, ", North"))
    par(op)
    dev.off()
}
if (tax[spp, "surroundinghf_south"]) {
    ress <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-south_", spp, ".Rdata")))
    ests_sp <- getEst(ress, stage=stage_hab_s + 2, na.out=FALSE, Xns)
    fname <- file.path(ROOT, "figs", "surroundinghf-south",
        paste0(as.character(tax[spp, "file"]), ".png"))
    png(file=fname, width=7.5, height=5.7, units="in", res=300)
    op <- par(mai=c(0.9,1,0.2,0.3))
    fig_hf_noremn(ests_sp, Xns, LAB=paste0(NAM, ", North"))
    par(op)
    dev.off()
}
}

## trend

res_trend <- matrix(NA, nrow(tax), 10)
colnames(res_trend) <- c("Mean_North","Median_North","LCL_North","UCL_North","n_North",
    "Mean_South","Median_South","LCL_South","UCL_South","n_South")
res_trend[,5] <- tax$ndet_n
res_trend[,10] <- tax$ndet_s
rownames(res_trend) <- rownames(tax)
for (spp in rownames(tax)) {
    cat(spp, "\n");flush.console()
if (tax[spp, "trend_north"]) {
    resn <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-north_", spp, ".Rdata")))
    estn_yr <- getEst(resn, stage=stage_hab_n + 3, na.out=FALSE, Xnn)
    yr_n <- 100 * (exp(estn_yr[,"YR"]) - 1)
    res_trend[spp, 1:4] <- fstat(yr_n)
    NDATN <- sum(yyn[,spp] > 0)
    NN <- aggregate(yyn[,spp], list(year=xnn$YEAR), mean)
}
if (tax[spp, "trend_south"]) {
    ress <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-south_", spp, ".Rdata")))
    ests_yr <- getEst(ress, stage=stage_hab_s + 3, na.out=FALSE, Xns)
    yr_s <- 100 * (exp(ests_yr[,"YR"]) - 1)
    res_trend[spp, 6:9] <- fstat(yr_s)
    NDATS <- sum(yys[,spp] > 0)
    NS <- aggregate(yys[,spp], list(year=xns$YEAR), mean)
}
if (tax[spp, "trend_north"] | tax[spp, "trend_south"]) {
    NAM <- as.character(tax[spp, "English_Name"])
    fname <- file.path(ROOT, "figs", "trend",
        paste0(as.character(tax[spp, "file"]), ".png"))
    png(file=fname, width=600, height=600)
    op <- par(mfrow=c(2,2), cex=0.8)
    if (tax[spp, "trend_north"]) {
        plot(NN, ylab="Annual Mean Abundance Index", xlab="Year",
            type="b", col=1, pch=19,
            main=paste0(NAM, ", North (n = ", NDATN, " detections)"))
        abline(lm(x ~ year, NN), col="red4", lty=1, lwd=2)
        hist(yr_n, col="gold", xlab="Decadal Trend (%)", main="")
        abline(v=fstat(yr_n)[1], col="red4", lty=1, lwd=2)
        abline(v=fstat(yr_n)[3:4], col="red4", lty=2, lwd=1)
    } else {
        plot.new()
        plot.new()
    }
    if (tax[spp, "trend_south"]) {
        plot(NS, ylab="Annual Mean Abundance Index", xlab="Year",
            type="b", col=1, pch=19,
            main=paste0(NAM, ", South (n = ", NDATS, " detections)"))
        abline(lm(x ~ year, NS), col="red4", lty=1, lwd=2)
        hist(yr_n, col="gold", xlab="Decadal Trend (%)", main="")
        abline(v=fstat(yr_s)[1], col="red4", lty=1, lwd=2)
        abline(v=fstat(yr_s)[3:4], col="red4", lty=2, lwd=1)
    } else {
        plot.new()
        plot.new()
    }
    par(op)
    dev.off()
}
}
res_trend2 <- data.frame(tax[,c("English_Name","Scientific_Name")], res_trend)
write.csv(res_trend2, file=file.path(ROOT, "figs", "trend.csv"))

rank_fun(res_trend$Mean_North, res_trend$LCL_North, res_trend$UCL_North,
    n=res_trend$n_North, col=1, lab = rownames(res_trend))

rank_fun(res_trend$Mean_South, res_trend$LCL_South, res_trend$UCL_South,
    n=res_trend$n_South, col=1, lab = rownames(res_trend))

## ARU effect
res_aru <- list()
for (spp in rownames(tax[tax$surroundinghf_north,])) {
    pres <- sum(yyn[substr(rownames(yyn), 1, 5) == "EMCLA",spp] > 0)
    if (pres > 0) {
        cat(spp, "\n");flush.console()
        resn <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-north_", spp, ".Rdata")))
        estn <- getEst(resn, stage=6, na.out=FALSE, Xnn)
        aru <- estn[,"ARU"]
        res_aru[[spp]] <- c(aru, pres)
    }
}
res_aru <- do.call(rbind, res_aru)
tmp <- res_aru[res_aru[,241]>19,-241]
tmp[tmp == 0] <- NA
rowMeans(exp(tmp), na.rm=TRUE)


## Linear features coefficients

spp <- "BTNW"
xlin <- nonDuplicated(xnn[,c("ROAD01","hab1","hab_lcc","hab_lcc2","hab_lcc3")],
    hab1, TRUE)
xlin <- xlin[c("Decid", "Mixwood", "Conif", "Pine", "BSpr", "Larch",
    "Decid", "Mixwood", "Conif", "Pine", "BSpr", "Larch",
    "GrassHerb", "Shrub", "Wetland", "Cult", "UrbInd"),]
rownames(xlin)[1:12] <- paste0(rep(rownames(xlin)[1:6], 2),
    rep(c("0-40","40+"), each=6))
xlin$ROAD01 <- 1
xlin$SoftLin_PC <- 0
xlin$hab_lcc[] <- c(4,4, 3,3,3,3, 2,2, 1,1,1,1, 5,5,5,5,5)
xlin$hab_lcc3 <- xlin$hab_lcc
levels(xlin$hab_lcc3) <- c("1", "1", "2", "2", "3")
xlin$hab_lcc2 <- xlin$hab_lcc
levels(xlin$hab_lcc2) <- c("1", "1", "1", "1", "2")


Xlin <- model.matrix(getTerms(modsn["Contrast"], "formula", intercept=TRUE), xlin)
colnames(Xlin) <- fixNames(colnames(Xlin))
Xlin <- Xlin[,-1]


res_soft <- list()
res_hard <- list()
for (spp in rownames(tax)) {
    cat(spp, "\n");flush.console()
    NAM <- as.character(tax[spp, "English_Name"])
if (tax[spp, "veghf_north"]) {
    resn <- loadSPP(file.path(ROOT, "results", paste0("birds_abmi-north_", spp, ".Rdata")))
    estn_lin <- getEst(resn, stage=stage_hab_n, na.out=FALSE, Xnn)
    colnames(estn_lin) <- fixNames(colnames(estn_lin))
    estn_lin2 <- estn_lin[,colnames(Xlin)]
    pr <- apply(estn_lin2, 1, function(z) Xlin %*% z)
    rownames(pr) <- rownames(xlin)
    tab <- t(apply(exp(pr), 1, quantile, c(0.5, 0.05, 0.95)))
    res_hard[[spp]] <- data.frame(Species=spp, Habitat=rownames(tab), tab)
    res_soft[[spp]] <- quantile(estn_lin[,"SoftLin_PC"], c(0.5, 0.05, 0.95))
}
}
## note: roadside stuff is exponentiated, but soft lin is not,
## because it is exp(x * est)

softlin <- data.frame(Species=tax[names(res_soft), "English_Name"], do.call(rbind, res_soft))
hardlin <- do.call(rbind, res_hard)
hardlin$Species <- tax[as.character(hardlin$Species), "English_Name"]

softlin <- droplevels(softlin[rownames(slt)[slt$veghf.north],])
hardlin <- droplevels(hardlin[hardlin$Species %in% softlin$Species,])

write.csv(softlin, row.names=FALSE,
    file=file.path(ROOT, "figs", "soft-linear-coefs-2015.csv"))
write.csv(hardlin, row.names=FALSE,
    file=file.path(ROOT, "figs", "hard-linear-EXPcoefs-2015.csv"))

softlin2 <- softlin[c("BTNW","BBWA","OVEN","BRCR","CAWA"),]
hardlin2 <- do.call(rbind, res_hard[c("BTNW","BBWA","OVEN","BRCR","CAWA")])
hardlin2$Species <- tax[as.character(hardlin2$Species), "English_Name"]

write.csv(softlin2, row.names=FALSE,
    file=file.path(ROOT, "figs", "soft-linear-coefs-2015-5spp.csv"))
write.csv(hardlin2, row.names=FALSE,
    file=file.path(ROOT, "figs", "hard-linear-EXPcoefs-2015-5spp.csv"))

## upland/lowland classification of species

tax2 <- read.csv("~/repos/abmispecies/_data/birds.csv")
rownames(tax2) <- tax2$AOU
tax3 <- read.csv("~/repos/abmianalytics/lookup/vertebrate-guilds.csv")
rownames(tax3) <- tax3$AOU.Code
setdiff(tax2$AOU[tax2$map.pred], tax3$AOU.Code)
setdiff(tax2$AOU[tax2$map.pred], tax$Species_ID)
SPP <- intersect(tax2$AOU[tax2$map.pred], tax3$AOU.Code)
tax2 <- droplevels(tax2[SPP,])
tax3 <- droplevels(tax3[SPP,])
native <- tax3[,grep("Native.to.", colnames(tax3))]
native[is.na(native)] <- 0
native[native > 0] <- 1
wet <- tax3[,c("General.Habitat.Category.Bog", "General.Habitat.Category.WetAq",
    "Wetland.Types.Wet_NestTerrOrWet", "Wetland.Types.Aq_NestTerrOrWet")]
wet[is.na(wet)] <- 0

tax2$native <- ifelse(rowSums(native)>0, 1, 0)
tax2 <- cbind(tax2, wet)

dat2 <- dat[dat$useOK & dat$keep,]
wetcl <- c("BSpr","Larch","Wetland")
dat2$strat <- as.factor(ifelse(dat2$hab1 %in% wetcl, "lowland", "upland"))
yy2 <- as.matrix(yy[rownames(dat2), SPP])
off2 <- e$OFFmean[rownames(dat2)]

table(dat2$strat, dat2$pWater >0.5)
dat2$strat[dat2$pWater >0.5] <- "lowland"

library(opticut)

XXX <- model.matrix(~ ROAD01 + SoftLin_PC, dat2)
oc1 <- opticut1(yy2[,1], XXX, dat2$strat, dist="poisson")

oc <- opticut(yy2 ~ ROAD01 + SoftLin_PC, dat2, strata=dat2$strat,
    offset=off2, dist="poisson", comb="rank")
os <- summary(oc)$summary
os <- os[SPP,]

tax2v <- data.frame(tax2[SPP,], os[SPP,])
tax2v$w <- NULL
tax2v$ndet_n <- NULL
tax2v$ndet_s <- NULL
tax2v$ndet_ns <- NULL
tax2v$map.det <- NULL
tax2v$veghf.north <- NULL
tax2v$soilhf.south <- NULL
tax2v$map.pred <- NULL
tax2v$useavail.north <- NULL
tax2v$useavail.south <- NULL
tax2v$lablo <- NULL
tax2v$labhi <- NULL

#levels(tax2v$split) <- c("lowland", "upland", "nopref")
#tax2v$split[tax2v$logLR < 2] <- "nopref"
table(tax2v$split)

tax2v$order <- tax3[SPP, "Order"]
tax2v$split2 <- as.character(tax2v$split)
tax2v$split2[] <- ""
tax2v$split2[tax2v$General.Habitat.Category.Bog +
    tax2v$General.Habitat.Category.WetAq > 0 & tax2v$split == "lowland"] <- "lowland"
tax2v$split2[tax2v$General.Habitat.Category.Bog +
    tax2v$General.Habitat.Category.WetAq == 0 & tax2v$split == "upland"] <- "upland"
tax2v$split2[tax2v$order %in% c("ANSERIFORMES","CHARADRIIFORMES","CICONIIFORMES",
    "PODICIPEDIFORMES","PELECANIFORMES","GAVIIFORMES","GRUIFORMES")] <- "lowland"
tax2v$split2[tax2v$order %in% c("COLUMBIFORMES","FALCONIFORMES",
    "GALLIFORMES","PICIFORMES","STRIGIFORMES")] <- "upland"
tax2v$split2[tax2v$native == 0] <- "nonnative"

table(tax2v$order,tax2v$split)
table(tax2v$split2)
write.csv(tax2v, file="~/birds-upland-lowland-classification.csv", row.names=FALSE)

