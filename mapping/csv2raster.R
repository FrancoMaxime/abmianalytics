##---
##title: "How to turn csv style tables into raster format"
##author: "Peter Solymos"
##date: "May 12, 2015"
##output:
##  pdf_document:
##    toc: false
##    toc_depth: 2
##---

### Intro
##
## The 'all-in-one' analyses will produce 1 km$^2$ level predictions
## in a format that lists predictions along with the cell ID.
## (Cell ID is a combination of raster row and column IDs.)
## We know the centroid of each raster cell (lat/long), and
## predicted values. This can be stored in a table and saved
## as a csv file. But people usually want predictions in raster
## format so that manipulation in GIS is straightforward.
## This script describes how to translate the csv style table
## (either created in R or read in from a text file)
## to a raster.

### Requirements

## Packages
library(raster)
library(sp)
library(rgdal)
library(mefa4)

## These requirements can be found on the FTP site.
## First the csv file that has lat/long, cell ID and a bunch of other
## variables (climate, regions, etc.) that we are using in modeling:
ROOT <- "c:/p"
VER <- "AB_data_v2015"
km <- read.csv(file.path(ROOT, VER, "data", "kgrid",
    "Grid1km_template_final_clippedBy_ABBound_with_atts_to_Peter.csv"))
colnames(km) <- toupper(colnames(km))
str(km)
## Here is the raster template:
rt <- raster(file.path(ROOT, VER, "data", "kgrid", "AHM1k.asc"))
plot(rt)
## Define projection
crs <- CRS("+proj=tmerc +lat_0=0 +lon_0=-115 +k=0.9992 +x_0=500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
projection(rt) <- crs

### Rasterize tables

## One needs to create the csv style table, so that lat/long and
## other variables of interest (current or reference abundance, intactness etc.)
## are matched by cell ID (rows). Here I use mean annuat temperature (MAT)
## as an example:
#xyz <- km[km$NRNAME == "Canadian Shield",c("POINT_X", "POINT_Y","MAT")]
## Defining the projection as WGS84:
#coordinates(xyz) <- ~ POINT_X + POINT_Y
#crs1 <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
#proj4string(xyz) <- crs1
## Reproject decimal degrees to the TM10 projection (used in the raster):
#crs2 <- CRS("+proj=tmerc +lat_0=0 +lon_0=-115 +k=0.9992 +x_0=500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")
#xyz <- spTransform(xyz, crs2)
#summary(xyz)
## Bounding boxes:
bbox(rt)
#bbox(xyz)
## Resolution
res(rt)
## This trivial conversion should work, but it does not, that is
## why this whole section is commented out:
#rout <- rasterize(xyz, rt, field="MAT", fun="first")

## Let us assume that the predicted values is a column named `Var` in the
## `km` data frame. We can then turn that into a matrix where each cell
## correspond to a raster cell. Thus using the `rt` raster object
## as a template, we can do what we want:
Var <- "MAT"
#nr <- length(unique(km[,"ROW"]))
#nc <- length(unique(km[,"COL"]))
#mat0 <- matrix(NA, nr, nc)
#for (i in 1:nrow(km)) {
#    mat0[km$ROW[i], km$COL[i]] <- km[[Var]][i]
#}
## A similar template can be created by:
mat0 <- as.matrix(rt)
## Or in a simpler fashion (thus only works if row x col values are unique):
mat <- as.matrix(Xtab(MAT ~ ROW + COL, km))
## Now we need to add in the NA values from `mat0`, but `mat0` needs to
## be created only once and can be used as a template:
mat[is.na(mat0)] <- NA
## Making sure that we did it right (row 1, col 2 is in the NW corner):
image(mat)
## Turn the matrix into a raster using `rt` as template:
rr <- raster(x=mat, template=rt)
plot(rr)
## Now we can save it, see `help(writeRaster)` for a
## description of output file formats:
#writeRaster(rr, file.path(ROOT, VER, "out", paste0(Var, ".asc")))

### Production quality maps

## Now we start a new process by using the raster we have just created:
library(dismo) 
ROOT <- "c:/p"
VER <- "AB_data_v2015"
r <- raster(file.path(ROOT, VER, "out", "MAT.asc"))
projection(r) <- CRS("+proj=tmerc +lat_0=0 +lon_0=-115 +k=0.9992 +x_0=500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs")

g <- gmap(r, type="terrain") 
r2 <- raster(g) 
dim(r2) <- dim(r) 
r2 <- projectRaster(r, r2) 

plot(g, scale=2) 
plot(r2, add=TRUE, alpha=0.75, axes=F,box=F,legend=F) 



## Use the `rasterVis` package for plotting:
library(rasterVis)
levelplot(r, contour=TRUE, par.settings=RdBuTheme)

## Adding points to the map (e.g. detections etc.)
