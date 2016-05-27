library(mefa4)

ROOT <- "e:/peter/AB_data_v2016/oracle"

det <- read.csv(file.path(ROOT, "birds-aru.csv"))

det <- droplevels(det[det$REPLICATE == 1, ]) # ~40 rows

## resolve duration
det$Duration <- NA
det$Duration[det$METHOD %in% c("11", "14")] <- 3
det$Duration[det$METHOD %in% c("12", "13")] <- 1

## format date/time
tmp <- paste(det$RECORDING_DATE, det$RECORDING_TIME)
det$Start <- strptime(tmp, "%d-%b-%y %H:%M:%S")

#det <- det[det$Spp != "NONE", ]

## first detection interval
det$int1 <- ifelse(det$MIN_1 == "VNA", NA, as.integer(det$MIN_1))
det$int2 <- ifelse(det$MIN_2 == "VNA", NA, as.integer(det$MIN_2))
det$int3 <- ifelse(det$MIN_3 == "VNA", NA, as.integer(det$MIN_3))
tmp <- col(det[,c("int1", "int2", "int3")])
tmp[is.na(det[,c("int1", "int2", "int3")])] <- Inf
tmp2 <- find_min(tmp)
tmp2$value[is.infinite(tmp2$value)] <- NA
det$Det1 <- tmp2$value

f <- function(x)
    ifelse(x == "VNA", NA, as.numeric(as.character(x)))
det$RAIN <- f(det$RAIN)
det$WIND <- f(det$WIND)
det$INDUSTRY <- f(det$INDUSTRY)
det$NOISE <- f(det$NOISE)
det$MICROPHONE <- f(det$MICROPHONE)

spp_keep <- unique(as.character(det$COMMON_NAME)[det$RANK_NAME == "Species"])
spp_keep <- spp_keep[spp_keep != "VNA"]
det$Spp <- det$COMMON_NAME
levels(det$Spp)[!(levels(det$Spp) %in% spp_keep)] <- "NONE"

## make sure not double counted: indiv_id # ~60 rows
tmp <- paste(det$RECORDING_KEY, det$Spp, det$INDIVIDUAL_ID)
tmp2 <- paste(det$RECORDING_KEY, det$Spp)
dc <- names(table(tmp))[table(tmp) > 1]
zz <- det[tmp %in% dc,]
zz <- zz[zz$Spp != "NONE",]
zz[,c("RECORDING_KEY", "Spp","INDIVIDUAL_ID", "int1", "int2", "int3")]
## leave it for now (until it is resolved at BU end)

det$site_stn <- interaction(det$SITE, det$STATION, drop=TRUE)

det$ToY <- det$Start$yday
det$ToYc <- as.integer(cut(det$ToY, c(0, 105, 120, 140, 150, 160, 170, 180, 365)))
det$visit <- interaction(det$site_stn, det$ToYc, drop=TRUE)

det$ToD <- det$Start$hour + det$Start$min / 60
det$ToDx <- round(det$ToD, 0)
det$ToDc <- as.factor(ifelse(det$ToDx == 0, "Midnight", "Morning"))


xt_stn <- as.matrix(Xtab(~ site_stn + Spp, det, cdrop="NONE"))
xt_vis <- as.matrix(Xtab(~ visit + Spp, det, cdrop="NONE"))

xt_tod <- data.frame(as.matrix(Xtab(~ Spp + ToDc, det, rdrop="NONE")))
xt_tod$MidP <- round(xt_tod$Midnight / (xt_tod$Midnight + xt_tod$Morning), 4)
xt_tod[order(xt_tod$MidP),]

xt_toy <- as.matrix(Xtab(~ Spp + ToYc, det, rdrop="NONE"))

Class <- nonDuplicated(det, visit, TRUE)
Class <- Class[rownames(xt_vis),]
Class$STR2 <- factor(NA, c("A", "B", "C"))
Class$STR2[Class$ToYc %in% 1:3] <- "A"
Class$STR2[Class$ToYc %in% 4:7] <- "B"
Class$STR2[Class$ToYc %in% 8] <- "C"
table(Class$STR2, Class$ToYc)


library(opticut)
xtv <- ifelse(xt_vis > 0, 1, 0)
oc2 <- opticut(xtv ~ 1, strata=Class$STR2, dist="binomial")
oc3 <- opticut(xtv ~ 1, strata=Class$ToDc, dist="binomial")

plot(oc2,sort=1)
summary(oc2)

summary(oc3)

table(det$ToYc, det$Duration)
## crosstab for all-in-one models

keep <- det$Duration == 3 & det$ToDc == "Morning"
keep[is.na(keep)] <- FALSE
det2 <- det[keep,]
det2$PKEY <- interaction(det2$SITE_LABEL, "_", det2$ToY, ":", 
    det2$Start$hour, ":", det2$Start$min, sep="", drop=TRUE)
xt <- as.matrix(Xtab(~ PKEY + Spp, det2, cdrop="NONE"))
x <- nonDuplicated(det2, PKEY, TRUE)
x <- x[rownames(xt), c("PKEY", "SITE_LABEL", "ROTATION", 
    "SITE", "YEAR", "STATION", "RAIN", "WIND", "INDUSTRY", "NOISE", "MICROPHONE", 
    "Start", "ToY", "ToD")]

OUTDIR <- "e:/peter/AB_data_v2016/data/species"
T <- "BirdsSM"
d <- paste("_", Sys.Date(), sep="")
save(det, xt, x, file=paste(OUTDIR, "/OUT_", tolower(T), d, ".Rdata",sep=""))



## --
library(mefa4)

ROOT <- "e:/peter/AB_data_v2016/data/aru-raw"

issu <- read.csv(file.path(ROOT, "2015-ABMI-MC-SC-AudioRecordingTranscription-issues.csv"))
depl <- read.csv(file.path(ROOT, "2015-ABMI-MC-SC-AudioRecordingTranscription-depl.csv"))
spp <- read.csv(file.path(ROOT, "2015-ABMI-MC-SC-AudioRecordingTranscription-spp.csv"))
det <- read.csv(file.path(ROOT, "2015-ABMI-MC-SC-AudioRecordingTranscription-det.csv"))

## resolve duration
det$Duration <- NA
det$Duration[det$Method %in% c(11, 14)] <- 3
det$Duration[det$Method %in% c(12, 13)] <- 1

## resolve species, none, unkn
levels(det$AOU_Code)
det$Spp <- det$AOU_Code
det$Spp[det$AOU_Code == ""] <- "NONE"
det$Spp[grepl("Unknown", as.character(det$ENGLISH.NAME))] <- "NONE"
det$Spp[spp$ORDER[match(det$AOU_Code, spp$CODE)] == "ABIOTIC"] <- "NONE"
det$Spp <- droplevels(det$Spp)
levels(det$Spp)

## format date/time
tmp <- paste(det$RECORDING_DATE, det$RECORD_TIME)
det$Start <- strptime(tmp, "%d-%b-%y %H:%M:%S")

det <- droplevels(det[det$Replicate == 1, ]) # ~40 rows
#det <- det[det$Spp != "NONE", ]

## first detection interval
tmp <- col(det[,c("X0min", "X1min", "X2min")])
tmp[is.na(det[,c("X0min", "X1min", "X2min")])] <- Inf
tmp2 <- find_min(tmp)
tmp2$value[is.infinite(tmp2$value)] <- NA
det$Det1 <- tmp2$value

det$site_stn <- interaction(det$SITE, det$STATION, drop=TRUE)

## make sure not double counted: indiv_id # ~60 rows
tmp <- paste(det$RecordingKey, det$Spp, det$INDIV_ID)
tmp2 <- paste(det$RecordingKey, det$Spp)
dc <- names(table(tmp))[table(tmp) > 1]
zz <- det[tmp %in% dc,]
zz <- zz[zz$Spp != "NONE",]
zz[,c("RecordingKey", "Spp","INDIV_ID", "X0min", "X1min", "X2min")]

#rec <- nonDuplicated(det[det$Replicate == 1, ], RecordingKey, TRUE)
rec <- nonDuplicated(det, RecordingKey, TRUE)
rec <- rec[,c("RecordingKey", "ProjectID", "Cluster", "SITE", "STATION", 
    "Year", "Round", "FileName", "RECORDING_DATE", "RECORD_TIME", 
    "Replicate", "Observer", "Rain", "Wind", "Industry", "Noise", 
    "Microphone", "ProsTime", "Method", "Comment.Recording", "Duration", "Start")]
rec$ToY <- rec$Start$yday
rec$ToD <- rec$Start$hour + rec$Start$min / 60
rec$ToDx <- round(rec$ToD, 0)

xt <- as.matrix(Xtab(~ ToY + ToDx, rec))
xt1 <- Xtab(~ ToY + ToDx + Duration, rec)
xt2 <- as.matrix(Xtab(~ Duration + ToDx, rec))

hist(rec$ToY)
hist(rec$ToD)
hist(rec$ToD[rec$Duration == 1])
hist(rec$ToD[rec$Duration == 3])

barplot(xt2)

aa=table(round(rec$ProsTime),rec$Duration)
aa <- aa[-(1:2),]
barplot(t(aa),beside=T)

table(det$Replicate)
table(det$Replicate, det$Method)

table(det$SITE, det$Duration)


table(rowSums(!is.na(det[det$Duration == 3,c("X0min", "X1min", "X2min")])))

det$ToY <- det$Start$yday
det$ToYc <- as.integer(cut(det$ToY, c(0, 105, 120, 140, 150, 160, 170, 180, 365)))
det$visit <- interaction(det$site_stn, det$ToYc, drop=TRUE)

det$ToD <- det$Start$hour + det$Start$min / 60
det$ToDx <- round(det$ToD, 0)
det$ToDc <- as.factor(ifelse(det$ToDx == 0, "Midnight", "Morning"))

xt_stn <- as.matrix(Xtab(~ site_stn + Spp, det, cdrop="NONE"))
xt_vis <- as.matrix(Xtab(~ visit + Spp, det, cdrop="NONE"))

xt_tod <- data.frame(as.matrix(Xtab(~ Spp + ToDc, det, rdrop="NONE")))
xt_tod$MidP <- round(xt_tod$Midnight / (xt_tod$Midnight + xt_tod$Morning), 4)
xt_tod[order(xt_tod$MidP),]

xt_toy <- as.matrix(Xtab(~ Spp + ToYc, det, rdrop="NONE"))

Class <- nonDuplicated(det, visit, TRUE)
Class <- Class[rownames(xt_vis),]
Class$STR2 <- factor(NA, c("A", "B", "C"))
Class$STR2[Class$ToYc %in% 1:3] <- "A"
Class$STR2[Class$ToYc %in% 4:7] <- "B"
Class$STR2[Class$ToYc %in% 8] <- "C"
table(Class$STR2, Class$ToYc)


library(opticut)
#oc <- opticut(xt_vis ~ 1, strata=Class$ToYc, dist="poisson")
xtv <- ifelse(xt_vis > 0, 1, 0)
oc <- opticut(xt_vis ~ 1, strata=Class$STR2, dist="poisson")
oc2 <- opticut(xtv ~ 1, strata=Class$STR2, dist="binomial")
plot(oc2,sort=1)
print(summary(oc2), cut=-Inf)

oc3 <- opticut(xtv ~ 1, strata=Class$ToDc, dist="binomial")
summary(oc3)

## todo:
## add common names to colnames
## increase left margin