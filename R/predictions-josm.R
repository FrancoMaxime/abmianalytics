## using veg based models only

library(mefa4)

shf <- TRUE

ROOT <- "e:/peter/AB_data_v2016"
ROOT2 <- "~/Dropbox/josm/2016/wewp"

OUTDIR1 <- "e:/peter/AB_data_v2016/out/birds/wewp/pred1"
OUTDIRB <- "e:/peter/AB_data_v2016/out/birds/wewp/predB"

load(file.path(ROOT, "out", "kgrid", "kgrid_table.Rdata"))
#source("~/repos/bragging/R/glm_skeleton.R")
source("~/repos/abmianalytics/R/results_functions.R")
#source("~/repos/bamanalytics/R/makingsense_functions.R")
regs <- levels(kgrid$LUFxNSR)
kgrid$useN <- !(kgrid$NRNAME %in% c("Grassland", "Parkland") | kgrid$NSRNAME == "Dry Mixedwood")
kgrid$useS <- kgrid$NRNAME == "Grassland"

e <- new.env()
load(file.path(ROOT, "out", "birds", "data", "data-full-withrevisit.Rdata"), envir=e)
tax <- e$TAX
rm(e)
tax$file <- nameAlnum(as.character(tax$English_Name), "mixed", "")

load(file.path(ROOT, "out", "transitions", paste0(regs[1], ".Rdata")))
Aveg <- rbind(colSums(trVeg))
rownames(Aveg) <- regs[1]
colnames(Aveg) <- colnames(trVeg)
Asoil <- rbind(colSums(trSoil))
rownames(Asoil) <- regs[1]
colnames(Asoil) <- colnames(trSoil)

for (i in 2:length(regs)) {
    cat(regs[i], "\n");flush.console()
    load(file.path(ROOT, "out", "transitions", paste0(regs[i], ".Rdata")))
    Aveg <- rbind(Aveg, colSums(trVeg))
    rownames(Aveg) <- regs[1:i]
    Asoil <- rbind(Asoil, colSums(trSoil))
    rownames(Asoil) <- regs[1:i]
}
## m^2 to ha
Aveg <- Aveg / 10^4
Asoil <- Asoil / 10^4


library(raster)
library(sp)
library(rgdal)
city <-data.frame(x = -c(114,113,112,111,117,118)-c(5,30,49,23,8,48)/60,
    y = c(51,53,49,56,58,55)+c(3,33,42,44,31,10)/60)
rownames(city) <- c("Calgary","Edmonton","Lethbridge","Fort McMurray",
    "High Level","Grande Prairie")
coordinates(city) <- ~ x + y
proj4string(city) <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
city <- spTransform(city, CRS("+proj=tmerc +lat_0=0 +lon_0=-115 +k=0.9992 +x_0=500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"))
city <- as.data.frame(city)

cex <- 0.25
legcex <- 1.5

Col1 <- rev(c("#D73027","#FC8D59","#FEE090","#E0F3F8","#91BFDB","#4575B4"))  # Colour gradient for reference and current
Col1fun <- colorRampPalette(Col1, space = "rgb") # Function to interpolate among these colours for reference and current
C1 <- Col1fun(100)
Col2 <- c("#C51B7D","#E9A3C9","#FDE0EF","#E6F5D0","#A1D76A","#4D9221")  # Colour gradient for difference map
Col2fun <- colorRampPalette(Col2, space = "rgb") # Function to interpolate among these colours for difference map
C2 <- Col2fun(200)
CW <- rgb(0.4,0.3,0.8) # water
CE <- "lightcyan4" # exclude

q <- 0.99
H <- 1000 
W <- 600


## sector effect

ch2veg <- t(sapply(strsplit(colnames(trVeg), "->"), 
    function(z) if (length(z)==1) z[c(1,1)] else z[1:2]))
ch2veg <- data.frame(ch2veg)
colnames(ch2veg) <- c("rf","cr")
rownames(ch2veg) <- colnames(Aveg)
ch2veg$uplow <- as.factor(ifelse(ch2veg$rf %in% c("BSpr0", "BSpr1", "BSpr2", "BSpr3", 
    "BSpr4", "BSpr5", "BSpr6", 
    "BSpr7", "BSpr8", "BSpr9", "BSprR", "Larch0", "Larch1", "Larch2", "Larch3",
    "Larch4", "Larch5", "Larch6", "Larch7", "Larch8", "Larch9", "LarchR",
    "WetGrassHerb", "WetShrub"), "lowland", "upland"))

ch2soil <- t(sapply(strsplit(colnames(trSoil), "->"), 
    function(z) if (length(z)==1) z[c(1,1)] else z[1:2]))
ch2soil <- data.frame(ch2soil)
colnames(ch2soil) <- c("rf","cr")
rownames(ch2soil) <- colnames(Asoil)

lxn <- nonDuplicated(kgrid[,c("LUF_NAME","NRNAME","NSRNAME")], kgrid$LUFxNSR, TRUE)
lxn$N <- lxn$NRNAME != "Grassland" & lxn$NRNAME != "Rocky Mountain" &
    lxn$NRNAME != "Parkland" & lxn$NSRNAME != "Dry Mixedwood"
lxn$S <- lxn$NRNAME == "Grassland" | lxn$NRNAME == "Parkland" |
    lxn$NSRNAME == "Dry Mixedwood"
table(lxn$NRNAME, lxn$N)
table(lxn$NRNAME, lxn$S)
lxn <- lxn[regs,]
all(rownames(Aveg) == regs)
all(rownames(Asoil) == regs)
AvegN <- colSums(Aveg[lxn$N,])
AvegN <- AvegN / sum(AvegN)
AsoilS <- colSums(Asoil[lxn$S,])
AsoilS <- AsoilS / sum(AsoilS)

tv <- read.csv("~/repos/abmianalytics/lookup/lookup-veg-hf-age.csv")
tv <- droplevels(tv[!is.na(tv$Sector),])
ts <- read.csv("~/repos/abmianalytics/lookup/lookup-soil-hf.csv")
ts <- droplevels(ts[!is.na(ts$Sector),])

## CoV
PROP <- 100
ks <- kgrid[kgrid$Rnd10 <= PROP,]
xy10 <- groupMeans(as.matrix(kgrid[,c("X","Y")]), 1, kgrid$Row10_Col10)

library(RColorBrewer)
br <- c(-1, 0.2, 0.4, 0.6, 0.8, 1, 1.2, 1.4, 1.6, 1.8, Inf)
Col <- rev(brewer.pal(10, "RdYlGn"))

## csv

SPP <- "WEWP"
spp <- SPP

if (FALSE) {
load(file.path(OUTDIR1, spp, paste0(regs[1], ".Rdata")))
rownames(pxNcr1) <- rownames(pxNrf1) <- names(Cells)
rownames(pxScr1) <- rownames(pxSrf1) <- names(Cells)
pxNcr <- pxNcr1
pxNrf <- pxNrf1
pxScr <- pxScr1
pxSrf <- pxSrf1
pSoil <- pSoil1
for (i in 2:length(regs)) {
    cat(spp, regs[i], "\n");flush.console()
    load(file.path(OUTDIR1, spp, paste0(regs[i], ".Rdata")))
    rownames(pxNcr1) <- rownames(pxNrf1) <- names(Cells)
    rownames(pxScr1) <- rownames(pxSrf1) <- names(Cells)
    pxNcr <- rbind(pxNcr, pxNcr1)
    pxNrf <- rbind(pxNrf, pxNrf1)
    pxScr <- rbind(pxScr, pxScr1)
    pxSrf <- rbind(pxSrf, pxSrf1)
    pSoil <- c(pSoil, pSoil1)
}

pxNcr <- pxNcr[rownames(kgrid),]
pxNrf <- pxNrf[rownames(kgrid),]
pxScr <- pxScr[rownames(kgrid),]
pxSrf <- pxSrf[rownames(kgrid),]
pSoil <- pSoil[rownames(kgrid)]

km1 <- data.frame(LinkID=kgrid$Row_Col,
    RefN=pxNrf,
    CurrN=pxNcr,
    RefS=pxSrf,
    CurrS=pxScr)
if (any(is.na(km1)))
    km1[is.na(km1)] <- 0
#NAM <- as.character(tax[spp, "English_Name"])
write.csv(km1, row.names=FALSE,
    paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0(as.character(tax[spp, "file"]), ".csv")))
}

## bootstrap results, only for veg

load(file.path(OUTDIRB, spp, paste0(regs[1], ".Rdata")))
rownames(pxNcrB) <- rownames(pxNrfB) <- names(Cells[Cells==1])
qcr <- quantile(pxNcrB, q)
pxNcrB[pxNcrB>qcr] <- qcr
qrf <- quantile(pxNrfB, q)
pxNrfB[pxNrfB>qrf] <- qrf
pxNcr <- fstatv(pxNcrB)
pxNrf <- fstatv(pxNrfB)
pxNcrSum <- matrix(colSums(pxNcrB), nrow=1)
pxNrfSum <- matrix(colSums(pxNrfB), nrow=1)

for (i in 2:length(regs)) {
    cat(spp, regs[i], "\n");flush.console()
    load(file.path(OUTDIRB, spp, paste0(regs[i], ".Rdata")))
    rownames(pxNcrB) <- rownames(pxNrfB) <- names(Cells[Cells==1])
    qcr <- quantile(pxNcrB, q)
    pxNcrB[pxNcrB>qcr] <- qcr
    qrf <- quantile(pxNrfB, q)
    pxNrfB[pxNrfB>qrf] <- qrf
    pxNcr <- rbind(pxNcr, fstatv(pxNcrB))
    pxNrf <- rbind(pxNrf, fstatv(pxNrfB))
    pxNcrSum <- rbind(pxNcrSum, matrix(colSums(pxNcrB), nrow=1))
    pxNrfSum <- rbind(pxNrfSum, matrix(colSums(pxNrfB), nrow=1))
}

pxNcr <- pxNcr[rownames(kgrid[kgrid$Rnd10 <= PROP,]),]
pxNrf <- pxNrf[rownames(kgrid[kgrid$Rnd10 <= PROP,]),]
rownames(pxNcrSum) <- rownames(pxNrfSum) <- regs

km <- data.frame(LinkID=kgrid$Row_Col[kgrid$Rnd10 <= PROP],
    RefN=pxNrf,
    CurrN=pxNcr)

if (any(is.na(km)))
    km[is.na(km)] <- 0
if (any(is.na(pxNrfSum)))
    pxNrfSum[is.na(pxNrfSum)] <- 0
if (any(is.na(pxNcrSum)))
    pxNcrSum[is.na(pxNcrSum)] <- 0

#NAM <- as.character(tax[spp, "English_Name"])
write.csv(km, row.names=FALSE,
    paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0("boot-long_", as.character(tax[spp, "file"]), ".csv")))
write.csv(pxNcrSum, row.names=TRUE,
    paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0("boot-sums-cr_", as.character(tax[spp, "file"]), ".csv")))
write.csv(pxNrfSum, row.names=TRUE,
    paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0("boot-sums-rf_", as.character(tax[spp, "file"]), ".csv")))


x <- read.csv(
    paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0("boot-long_", as.character(tax[spp, "file"]), ".csv")))

library(raster)
source("~/repos/abmianalytics/R/maps_functions.R")
rt <- raster(file.path(ROOT, "data", "kgrid", "AHM1k.asc"))
x_cr_mean <- as_Raster(kgrid$Row, kgrid$Col, x$CurrN.Mean, rt)
x_rf_mean <- as_Raster(kgrid$Row, kgrid$Col, x$RefN.Mean, rt)
x_cr_cov <- as_Raster(kgrid$Row, kgrid$Col, x$CurrN.SD / x$CurrN.Mean, rt)
writeRaster(x_cr_mean, 
    paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0("Mean-current_", as.character(tax[spp, "file"]), ".asc")))
writeRaster(x_rf_mean, 
    paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0("Mean-reference_", as.character(tax[spp, "file"]), ".asc")))
writeRaster(x_cr_cov, 
    paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0("CoV-current_", as.character(tax[spp, "file"]), ".asc")))


## plots

km1 <- read.csv(paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0(as.character(tax[spp, "file"]), ".csv")))
km <- read.csv(paste0("e:/peter/AB_data_v2016/out/birds/wewp/", 
    paste0("boot-long_", as.character(tax[spp, "file"]), ".csv")))

    cr <- km$CurrN.Mean
    rf <- km$RefN.Mean
    qcr <- quantile(cr, q)
    cr[cr>qcr] <- qcr
    qrf <- quantile(rf, q)
    rf[rf>qrf] <- qrf

    Max <- max(qcr, qrf)
    df <- (cr-rf) / Max
    df <- sign(df) * abs(df)^0.5
    df <- pmin(200, ceiling(99 * df)+100)
    df[df==0] <- 1
    cr <- pmin(100, ceiling(99 * sqrt(cr / Max))+1)
    rf <- pmin(100, ceiling(99 * sqrt(rf / Max))+1)
    range(cr)
    range(rf)
    range(df)

    NAM <- as.character(tax[spp, "English_Name"])
    TAG <- ""
    WPROP <- 0.8
    
    png(paste0("e:/peter/AB_data_v2016/out/birds/wewp/reference-",
        as.character(tax[spp, "file"]), TAG, ".png"),
        width=W, height=H)
    op <- par(mar=c(0, 0, 4, 0) + 0.1)
    plot(kgrid$X, kgrid$Y, col=C1[rf], pch=15, cex=cex, ann=FALSE, axes=FALSE)
    with(kgrid[kgrid$pWater > WPROP,], points(X, Y, col=CW, pch=15, cex=cex))
    mtext(side=3,paste(NAM, "\nReference abundance"),col="grey30", cex=legcex)
    points(city, pch=18, cex=cex*3)
    text(city[,1], city[,2], rownames(city), cex=0.8, adj=-0.1, col="grey10")
    par(op)
    dev.off()

    png(paste0("e:/peter/AB_data_v2016/out/birds/wewp/current-",
        as.character(tax[spp, "file"]), TAG, ".png"),
        width=W, height=H)
    op <- par(mar=c(0, 0, 4, 0) + 0.1)
    plot(kgrid$X, kgrid$Y, col=C1[cr], pch=15, cex=cex, ann=FALSE, axes=FALSE)
    with(kgrid[kgrid$pWater > WPROP,], points(X, Y, col=CW, pch=15, cex=cex))
    mtext(side=3,paste(NAM, "\nCurrent abundance"),col="grey30", cex=legcex)
    points(city, pch=18, cex=cex*3)
    text(city[,1], city[,2], rownames(city), cex=0.8, adj=-0.1, col="grey10")
    par(op)
    dev.off()

    png(paste0("e:/peter/AB_data_v2016/out/birds/wewp/difference-",
        as.character(tax[spp, "file"]), TAG, ".png"),
        width=W, height=H)
    op <- par(mar=c(0, 0, 4, 0) + 0.1)
    plot(kgrid$X, kgrid$Y, col=C2[df], pch=15, cex=cex, ann=FALSE, axes=FALSE)
    with(kgrid[kgrid$pWater > WPROP,], points(X, Y, col=CW, pch=15, cex=cex))
    mtext(side=3,paste(NAM, "\nDifference"),col="grey30", cex=legcex)
    points(city, pch=18, cex=cex*3)
    text(city[,1], city[,2], rownames(city), cex=0.8, adj=-0.1, col="grey10")
    par(op)
    dev.off()

    covC <- km$CurrN.SD / km$CurrN.Mean
    sum(is.na(covC))
    sum(is.na(covC)) / length(covC)
    covC[is.na(covC)] <- 2
    zval <- as.integer(cut(covC, breaks=br))

    png(paste0("e:/peter/AB_data_v2016/out/birds/wewp/cov-",
        as.character(tax[spp, "file"]), ".png"),
        width=W, height=H)
    op <- par(mar=c(0, 0, 4, 0) + 0.1)
    plot(kgrid$X, kgrid$Y, col=Col[zval], pch=15, cex=cex, ann=FALSE, axes=FALSE)
    with(kgrid[kgrid$pWater > WPROP,], points(X, Y, col=CW, pch=15, cex=cex))
    mtext(side=3,paste(NAM, "CoV"),col="grey30", cex=legcex)
    points(city, pch=18, cex=cex*3)
    text(city[,1], city[,2], rownames(city), cex=0.8, adj=-0.1, col="grey10")
    TEXT <- paste0(100*br[-length(br)], "-", 100*br[-1])
    INF <- grepl("Inf", TEXT)
    if (any(INF))
        TEXT[length(TEXT)] <- paste0(">", 100*br[length(br)-1])
    TITLE <- "Coefficient of variation"
    legend("bottomleft", border=rev(Col), fill=rev(Col), bty="n", legend=rev(TEXT),
                title=TITLE, cex=legcex*0.8)
    par(op)
    dev.off()


## Abundance by NR

sum(km1$RefN)
sum(km$RefN.Mean)
sum(km$RefN.Median)
sum(pxNrfSum) / ncol(pxNrfSum)

sum(km1$CurrN)
sum(km$CurrN.Mean)
sum(km$CurrN.Median)
sum(pxNcrSum) / ncol(pxNcrSum)

## values are D/ha, need to x100 to get N in 1km^2 pixel
trf <- groupSums(pxNrfSum*100, 1, lxn$NRNAME)
trf <- rbind(trf, Total=colSums(trf))
tcr <- groupSums(pxNcrSum*100, 1, lxn$NRNAME)
tcr <- rbind(tcr, Total=colSums(tcr))
Tab <- data.frame(rbind(Reference=round(nrrf <- fstatv(trf, 0.9)),
    Current=round(nrcr <- fstatv(tcr, 0.9)),
    Change=round(fstatv(100 * (tcr - trf) / trf, 0.9), 2)))
write.csv(Tab, file=paste0("e:/peter/AB_data_v2016/out/birds/wewp/pop-est-",
        as.character(tax[spp, "file"]), ".csv"))

## ---------------

## sector effects
seff_res <- list()
#seff_luf <- list()
#seff_ns <- list()
uplow <- list()
uplow_full <- list()
uplow_luf <- list()

## stuff to exclude
## add col to lxn
## subset counter for loop


for (spp in as.character(slt$AOU[slt$map.pred])) {

cat(spp, "\n");flush.console()

load(file.path(OUTDIR1, spp, paste0(regs[1], ".Rdata")))
hbNcr <- hbNcr1[,1]
hbNrf <- hbNrf1[,1]
hbScr <- hbScr1[,1]
hbSrf <- hbSrf1[,1]
for (i in 2:length(regs)) {
    cat(spp, regs[i], "\n");flush.console()
    load(file.path(OUTDIR1, spp, paste0(regs[i], ".Rdata")))
    hbNcr <- rbind(hbNcr, hbNcr1[,1])
    hbNrf <- rbind(hbNrf, hbNrf1[,1])
    hbScr <- rbind(hbScr, hbScr1[,1])
    hbSrf <- rbind(hbSrf, hbSrf1[,1])
}

dimnames(hbNcr) <- dimnames(hbNrf) <- list(regs, colnames(Aveg))
hbNcr[is.na(hbNcr)] <- 0
hbNrf[is.na(hbNrf)] <- 0
hbNcr <- hbNcr * Aveg
hbNrf <- hbNrf * Aveg

dimnames(hbScr) <- dimnames(hbSrf) <- list(regs, colnames(Asoil))
hbScr[is.na(hbScr)] <- 0
hbSrf[is.na(hbSrf)] <- 0
hbScr <- hbScr * Asoil
hbSrf <- hbSrf * Asoil


## combined upland/lowland N/S
crN <- groupSums(hbNcr, 2, ch2veg$uplow)
rfN <- groupSums(hbNrf, 2, ch2veg$uplow)
crN[lxn$NRNAME=="Grassland","lowland"] <- 0 
crN[lxn$NRNAME=="Grassland","upland"] <- rowSums(hbScr[lxn$NRNAME=="Grassland",])
rfN[lxn$NRNAME=="Grassland","lowland"] <- 0 
rfN[lxn$NRNAME=="Grassland","upland"] <- rowSums(hbSrf[lxn$NRNAME=="Grassland",])
uplo <- data.frame(Current=crN, Reference=rfN)
uplow_full[[spp]] <- data.frame(sppid=spp, lxn[,1:3], uplo)

## Exclude stuff here
r0 <- lxn$NSRNAME %in% c("Alpine","Lower Foothills",
    "Montane","Subalpine","Upper Foothills")
crN[r0,] <- 0
rfN[r0,] <- 0

## upland/lowland
cr <- colSums(crN)
rf <- colSums(rfN)
cr <- c(total=sum(cr), cr)
rf <- c(total=sum(rf), rf)
si <- 100 * pmin(cr, rf) / pmax(cr, rf)
si2 <- ifelse(cr > rf, 200-si, si)
uplow[[spp]] <- c(Ref=rf, Cur=cr, SI=si, SI200=si2)

cr <- groupSums(groupSums(hbNcr, 2, ch2veg$uplow), 1, lxn$LUF_NAME)
rf <- groupSums(groupSums(hbNrf, 2, ch2veg$uplow), 1, lxn$LUF_NAME)
cr <- cbind(total=rowSums(cr), cr)
rf <- cbind(total=rowSums(rf), rf)
si <- sapply(1:3, function(i) 100 * pmin(cr[,i], rf[,i]) / pmax(cr[,i], rf[,i]))
colnames(si) <- colnames(cr)
si2 <- ifelse(cr > rf, 200-si, si)

uplow_luf[[spp]] <- data.frame(ID=spp, Ref=round(rf), Cur=round(cr), 
    SI=round(si, 2), SI200=round(si2, 2))

ThbNcr <- colSums(hbNcr[lxn$N,])
ThbNrf <- colSums(hbNrf[lxn$N,])
df <- (ThbNcr - ThbNrf) / sum(ThbNrf)
dA <- Xtab(AvegN ~ rf + cr, ch2veg)
if (FALSE) {
    tv <- read.csv("~/repos/abmianalytics/lookup/lookup-veg-hf-age.csv")
    tv2 <- nonDuplicated(tv,Combined,TRUE)
    dA2 <- as.matrix(groupSums(dA[,rownames(tv2)], 2, tv2$Sector3))
    tv3 <- tv2[rownames(dA2),]
    dA2 <- as.matrix(groupSums(dA2, 1, tv3$Sector3))
    dA3 <- dA2[,c(c("Agriculture","Forestry","Energy","RuralUrban","Transportation"))]
    dA3 <- round(100*t(t(dA3) / colSums(dA3)), 1)
    dA3[c("Decid", "Mixwood", "UpConif", "LoConif", "Wet", "OpenOther"),]
}

dN <- Xtab(df ~ rf + cr, ch2veg)
#dA <- colSums(as.matrix(groupSums(dA[,rownames(tv)], 2, tv$Sector2)))
#dN <- colSums(as.matrix(groupSums(dN[,rownames(tv)], 2, tv$Sector2)))
dA <- colSums(as.matrix(groupSums(dA[,rownames(tv)], 2, tv$Sector)))
dN <- colSums(as.matrix(groupSums(dN[,rownames(tv)], 2, tv$Sector)))
U <- dN/dA
seffN <- cbind(dA=dA, dN=dN, U=U)[c("Agriculture","Forestry",
    "Energy",#"EnergySoftLin","MineWell",
    "RuralUrban","Transportation"),]

ThbScr <- colSums(hbScr[lxn$S,])
ThbSrf <- colSums(hbSrf[lxn$S,])
df <- (ThbScr - ThbSrf) / sum(ThbSrf)
dA <- Xtab(AsoilS ~ rf + cr, ch2soil)
dN <- Xtab(df ~ rf + cr, ch2soil)
#dA <- colSums(as.matrix(groupSums(dA[,rownames(ts)], 2, ts$Sector2)))
#dN <- colSums(as.matrix(groupSums(dN[,rownames(ts)], 2, ts$Sector2)))
dA <- colSums(as.matrix(groupSums(dA[,rownames(ts)], 2, ts$Sector)))
dN <- colSums(as.matrix(groupSums(dN[,rownames(ts)], 2, ts$Sector)))
U <- dN/dA
seffS <- cbind(dA=dA, dN=dN, U=U)[c("Agriculture","Forestry",
    "Energy",#"EnergySoftLin","MineWell",
    "RuralUrban","Transportation"),]
seff_res[[spp]] <- list(N=seffN, S=seffS)

#(sum(hbNcr)-sum(hbNrf))/sum(hbNrf)
#(sum(km$CurrN)-sum(km$RefN))/sum(km$RefN)
#100*seff

}

#save(slt, seff_res, file=file.path(ROOT, "out", "birds", "sector-effects-e2.Rdata"))
save(slt, seff_res, uplow, uplow_luf, uplow_full, file=file.path(ROOT, "out", "birds", "sector-effects.Rdata"))
#load(file.path(ROOT, "out", "birds", "sector-effects.Rdata"))

nres <- list()
sres <- list()
for (spp in names(seff_res)) {
    nres[[spp]] <- 100*c(PopEffect=seff_res[[spp]]$N[,2], UnitEffect=seff_res[[spp]]$N[,3])
    sres[[spp]] <- 100*c(PopEffect=seff_res[[spp]]$S[,2], UnitEffect=seff_res[[spp]]$S[,3])
}
nres <- do.call(rbind, nres)
sres <- do.call(rbind, sres)
nres <- data.frame(Species=slt[rownames(nres), "species"], nres)
sres <- data.frame(Species=slt[rownames(sres), "species"], sres)

uplow <- do.call(rbind, uplow)
uplow <- data.frame(Species=slt[rownames(uplow), "species"], uplow)

summary(uplow$Cur.total)
sum(uplow$Cur.total >= 10^7)
uplow2 <- uplow[uplow$Cur.total < 10^7,]
#sum(uplow$Cur.total <= 1)
#uplow2 <- uplow2[uplow$Cur.total > 0,]

write.csv(uplow2, row.names=FALSE,
    file="e:/peter/sppweb-html-content/species/birds/Birds_UplandLowlandIntactness.csv")

write.csv(nres, row.names=FALSE,
    file="e:/peter/sppweb-html-content/species/birds/Birds_SectorEffects_North.csv")
write.csv(sres, row.names=FALSE,
    file="e:/peter/sppweb-html-content/species/birds/Birds_SectorEffects_South.csv")

siLUF <- data.frame(Species=NA, LUF=rownames(uplow_luf[[1]]), do.call(rbind, uplow_luf))
siLUF$Species <- slt$species[match(siLUF$ID, slt$AOU)]
ta <- aggregate(siLUF$Cur.total, list(ID=siLUF$ID), sum)
keep <- as.character(ta$ID[ta$x < 10^7 & ta$x > 0.5])
siLUF <- siLUF[siLUF$ID %in% keep,]
siLUF$ID <- NULL
write.csv(siLUF, row.names=FALSE,
    file="e:/peter/sppweb-html-content/species/birds/Birds_UplandLowlandIntactness-by-LUF.csv")

allluf <- do.call(rbind, uplow_full)
allluf <- data.frame(slt[match(allluf$sppid, slt$AOU),c("species","scinam")], 
    LUF_NSR=interaction(allluf$LUF_NAME, allluf$NSRNAME, drop=TRUE, sep="_"), allluf)
write.csv(allluf, row.names=FALSE,
    file="e:/peter/sppweb-html-content/species/birds/Birds_UplandLowland-by-LUF-NSR.csv")


for (spp in as.character(slt$AOU[slt$map.pred])) {
cat(spp, "\n");flush.console()

for (WHERE in c("N", "S")) {
if (slt[spp, ifelse(WHERE=="N","veghf.north", "soilhf.south")]) {
SEFF <- seff_res[[spp]][[WHERE]]

## Sector effect plot from Dave
## Sectors to plot and their order
sectors <- c("Agriculture","Forestry",
    "Energy",#"EnergySoftLin","MineWell",
    "RuralUrban","Transportation")
## Names that will fit without overlap  
sector.names <- c("Agriculture","Forestry",
    "Energy",#"EnergySL","EnergyEX",
    "RuralUrban","Transport")
## The colours for each sector above
c1 <- c("tan3","palegreen4","indianred3",#"hotpink4",
    "skyblue3","slateblue2")  
total.effect <- 100 * SEFF[sectors,"dN"]
unit.effect <- 100 * SEFF[sectors,"U"]
## Max y-axis at 20%, 50% or 100% increments 
## (made to be symmetrical with y-min, except if y-max is >100
ymax <- ifelse(max(abs(unit.effect))<20,20,
    ifelse(max(abs(unit.effect))<50,50,round(max(abs(unit.effect))+50,-2)))  
ymin <- ifelse(ymax>50,min(-100,round(min(unit.effect)-50,-2)),-ymax)
## This is to leave enough space at the top of bars for the text giving the % population change
ymax <- max(ymax,max(unit.effect)+0.08*(max(unit.effect)-min(unit.effect,0))) 
## This is to leave enough space at the bottom of negative bars for the 
## text giving the % population change
ymin <- min(ymin,min(unit.effect)-0.08*(max(unit.effect,0)-min(unit.effect))) 

NAM <- as.character(tax[spp, "English_Name"])
TAG <- ""

png(paste0("e:/peter/sppweb-html-content/species/birds/sector-",
    ifelse(WHERE=="N", "north/", "south/"),
    as.character(tax[spp, "file"]), TAG, ".png"),
    width=600, height=600)

q <- barplot(unit.effect,
    width=100 * SEFF[sectors,"dA"],
    space=0,col=c1,border=c1,ylim=c(ymin,ymax),
    ylab="Unit effect (%)",xlab="Area (% of region)",
    xaxt="n",cex.lab=1.3,cex.axis=1.2,tcl=0.3,
    xlim=c(0,round(sum(100 * SEFF[,"dA"])+1,0)),
    bty="n",col.axis="grey40",col.lab="grey40",las=2)

rect(par("usr")[1],par("usr")[3],par("usr")[2],par("usr")[4],col = "gray88",border="gray88")
x.at<-pretty(c(0,sum(100 * SEFF[,"dA"])))
axis(side=1,tck=1,at=x.at,lab=rep("",length(x.at)),col="grey95")
y.at<-pretty(c(ymin,ymax),n=6)
axis(side=2,tck=1,at=y.at,lab=rep("",length(y.at)),col="grey95")
q <- barplot(unit.effect,
    width=100 * SEFF[sectors,"dA"],
    space=0,col=c1,border=c1,ylim=c(ymin,ymax),
    ylab="Unit effect (%)",xlab="Area (% of region)",
    xaxt="n",cex.lab=1.3,cex.axis=1.2,tcl=0.3,
    xlim=c(0,round(sum(100 * SEFF[,"dA"])+1,0)),
    bty="n",col.axis="grey40",col.lab="grey40",las=2,add=TRUE)
box(bty="l",col="grey40")
mtext(side=1,line=2,at=x.at,x.at,col="grey40",cex=1.2)
axis(side=1,at=x.at,tcl=0.3,lab=rep("",length(x.at)),col="grey40",
    col.axis="grey40",cex.axis=1.2,las=1)
abline(h=0,lwd=2,col="grey40")
## Set the lines so that nearby labels don't overlap
mtext(side=1,at=q+c(0,0,-1,0,+1),sector.names,col=c1,cex=1.3,
    adj=0.5,line=c(0.1,0.1,1.1,0.1,1.1))  
## Just above positive bars, just below negative ones
y <- unit.effect+0.025*(ymax-ymin)*sign(unit.effect)  
## Make sure there is no y-axis overlap in % change labels of 
## sectors that are close together on x-axis
if (abs(y[3]-y[4])<0.05*(ymax-ymin))  
    y[3:4]<-mean(y[3:4])+(c(-0.015,0.015)*(ymax-ymin))[rank(y[3:4])]   
## Make sure there is no y-axis overlap in % change labels of sectors 
## that are close together on x-axis
if (abs(y[4]-y[5])<0.05*(ymax-ymin))  
    y[4:5]<-mean(y[4:5])+(c(-0.015,0.015)*(ymax-ymin))[rank(y[4:5])]   
#if (abs(y[5]-y[6])<0.05*(ymax-ymin))  
#    y[5:6]<-mean(y[5:6])+(c(-0.015,0.015)*(ymax-ymin))[rank(y[5:6])]   
text(q,y,paste(ifelse(total.effect>0,"+",""),
    sprintf("%.1f",total.effect),"%",sep=""),col="darkblue",cex=1.4)
mtext(side=3,line=1,at=0,adj=0, 
    paste0(NAM, " - ", ifelse(WHERE=="N", "North", "South")),
    cex=1.4,col="grey40")
dev.off()
}
}
}

## CoV
results10km_list <- list()

SPP <- as.character(slt$AOU[slt$map.pred])
for (spp in SPP) {

    load(file.path(OUTDIRB, spp, paste0(regs[1], ".Rdata")))
    rownames(pxNcrB) <- rownames(pxNrfB) <- names(Cells)[Cells == 1]
    rownames(pxScrB) <- rownames(pxSrfB) <- names(Cells)[Cells == 1]
    pxNcr0 <- pxNcrB
    #pxNrf0 <- pxNrfB
    pxScr0 <- pxScrB
    #pxSrf0 <- pxSrfB
    for (i in 2:length(regs)) {
        cat(spp, regs[i], "\n");flush.console()
        load(file.path(OUTDIRB, spp, paste0(regs[i], ".Rdata")))
        rownames(pxNcrB) <- rownames(pxNrfB) <- names(Cells)[Cells == 1]
        rownames(pxScrB) <- rownames(pxSrfB) <- names(Cells)[Cells == 1]
        pxNcr0 <- rbind(pxNcr0, pxNcrB)
    #    pxNrf0 <- rbind(pxNrf0, pxNrfB)
        pxScr0 <- rbind(pxScr0, pxScrB)
    #    pxSrf0 <- rbind(pxSrf0, pxSrfB)
    }

    pxNcr <- pxNcr0[rownames(ks),]
    #pxNrf <- pxNrf0[rownames(ks),]
    pxScr <- pxScr0[rownames(ks),]
    pxScr[is.na(pxScr)] <- 0
    #pxSrf <- pxSrf0[rownames(ks),]
    for (k in 1:ncol(pxNcr)) {
        qN <- quantile(pxNcr[is.finite(pxNcr[,k]),k], q, na.rm=TRUE)
        pxNcr[pxNcr[,k] > qN,k] <- qN
        qS <- quantile(pxScr[is.finite(pxScr[,k]),k], q, na.rm=TRUE)
        pxScr[pxScr[,k] > qS,k] <- qS
    }

TYPE <- "C" # combo
if (!slt[spp, "veghf.north"])
    TYPE <- "S"
if (!slt[spp, "soilhf.south"])
    TYPE <- "N"

wS <- 1-ks$pAspen
if (TYPE == "S")
    wS[] <- 1
if (TYPE == "N")
    wS[] <- 0
wS[ks$useS] <- 1
wS[ks$useN] <- 0

    cr <- wS * pxScr + (1-wS) * pxNcr

    crveg <- groupMeans(cr, 1, ks$Row10_Col10, na.rm=TRUE)

results10km_list[[as.character(slt[spp,"sppid"])]] <- crveg

    crvegm <- rowMeans(crveg)
    crvegsd <- apply(crveg, 1, sd)
    #crvegm <- apply(crveg, 1, median)
    #crvegsd <- apply(crveg, 1, IQR)
    covC <- crvegsd / crvegm
    #covN[is.na(covN)] <- 1

    #crsoil <- groupMeans(pxScr, 1, ks$Row10_Col10)
    #crsoilm <- rowMeans(crsoil)
    #crsoilsd <- apply(crsoil, 1, sd)
    #crsoilm <- apply(crsoil, 1, median)
    #crsoilsd <- apply(crsoil, 1, IQR)
    #covS <- crsoilsd / crsoilm
    #covS[is.na(covS)] <- 1

#px <- crveg[order(crvegm),]
#matplot(crvegm[order(crvegm)], crveg, type="l", lty=1)


    NAM <- as.character(tax[spp, "English_Name"])

    zval <- as.integer(cut(covC, breaks=br))
    zval <- zval[match(kgrid$Row10_Col10, rownames(crveg))]

    cat(spp, "saving CoV map\n\n");flush.console()
    png(paste0("e:/peter/sppweb-html-content/species/birds/map-cov-cr/",
        as.character(tax[spp, "file"]), ".png"),
        width=W, height=H)
    op <- par(mar=c(0, 0, 4, 0) + 0.1)
    plot(kgrid$X, kgrid$Y, col=Col[zval], pch=15, cex=cex, ann=FALSE, axes=FALSE)
    with(kgrid[kgrid$pWater > 0.99,], points(X, Y, col=CW, pch=15, cex=cex))
#    with(kgrid[kgrid$NRNAME == "Rocky Mountain" & kgrid$POINT_X < -112,], 
#        points(X, Y, col=CE, pch=15, cex=cex))
    if (TYPE == "N")
        with(kgrid[kgrid$useS,], points(X, Y, col=CE, pch=15, cex=cex))
    if (TYPE == "S")
        with(kgrid[kgrid$useN,], points(X, Y, col=CE, pch=15, cex=cex))
    mtext(side=3,paste(NAM, "CoV"),col="grey30", cex=legcex)
    points(city, pch=18, cex=cex*2)
    text(city[,1], city[,2], rownames(city), cex=0.8, adj=-0.1, col="grey10")
#	text(378826,5774802,"Insufficient \n   data",col="white",cex=0.9)

    TEXT <- paste0(100*br[-length(br)], "-", 100*br[-1])
    INF <- grepl("Inf", TEXT)
    if (any(INF))
        TEXT[length(TEXT)] <- paste0(">", 100*br[length(br)-1])

    TITLE <- "Coefficient of variation"
    legend("bottomleft", border=rev(Col), fill=rev(Col), bty="n", legend=rev(TEXT),
                title=TITLE, cex=legcex*0.8)
    par(op)
    dev.off()


}

xy10km <- ks[,c("POINT_X","POINT_Y","Row10_Col10")]
save(xy10km, results10km_list, file="w:/species/birds-provincial-10x10km-summary.Rdata")


