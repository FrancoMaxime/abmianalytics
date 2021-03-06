## takes xy coordinates and a corresponding vector z
## and turns it into a raster using raster template r
as_Raster0 <-
function(x, y, z, r)
{
    mat0 <- as.matrix(r)
    mat <- as.matrix(Xtab(z ~ x + y))
    mat[is.na(mat0)] <- NA
    raster(x=mat, template=r)
}
## does the same but creates a raster stack when z is matrix
as_Raster <-
function(x, y, z, r, verbose=0)
{
    if (is.null(dim(z))) {
        out <- as_Raster0(x, y, z, r)
    } else {
        if (verbose) {
            cat("rasterizing: 1\n")
            flush.console()
        }
        out <- as_Raster0(x, y, z[,1], r)
        for (i in 2:ncol(z)) {
            if (verbose) {
                cat("rasterizing:", i, "\n")
                flush.console()
            }
            tmp <- as_Raster0(x, y, z[,i], r)
            out <- stack(out, tmp)
        }
        names(out) <- if (is.null(colnames(z)))
            paste0("V", seq_len(ncol(z))) else colnames(z)
    }
    out
}

map_fun <-
function(x, q=1, main="", colScale="terrain",
plotWater=TRUE, maskRockies=TRUE, plotCities=TRUE, legend=TRUE,
mask=NULL)
{
    ## these might need to be truncated to have pale in the middle
    if (is.character(colScale)) {
        col <- switch(colScale,
            "terrain" = rev(terrain.colors(255)),
            "heat" = rev(heat.colors(255)),
            "topo" = rev(topo.colors(255)),
            "grey" = grey(seq(1,0,len=255)),
            "hf" = colorRampPalette(brewer.pal("YlOrRd", n=9)[1:6])(255),
            "intactness" = colorRampPalette(c("red","green"))(255),
            "soil" = colorRampPalette(brewer.pal("Oranges", n=9)[1:6])(255),
            "abund" = colorRampPalette(rev(c("#D73027","#FC8D59","#FEE090","#E0F3F8",
                "#91BFDB","#4575B4")))(255),
            "diff" = colorRampPalette(c("#C51B7D","#E9A3C9","#FDE0EF","#E6F5D0",
                "#A1D76A","#4D9221"))(255))
    } else {
        col <- colScale(255)
    }

    r <- if (inherits(x, "RasterLayer"))
        x else as_Raster(kgrid$Row, kgrid$Col, x, rt)
    r[r > quantile(r, q)] <- quantile(r, q)
    ## output raster should be masked as well
    if (maskRockies)
        r[!is.na(r_mask)] <- NA
    if (!is.null(mask))
        r[mask == 1L] <- NA
    ## mask >99% water cells
    r[r_water > 0.99] <- NA

    plot(r, axes=FALSE, box=FALSE, legend=legend,
        main=main, maxpixels=10^6, col=col, interpolate=FALSE)

    if (plotWater && !maskRockies) {
        plot(r_water, add=TRUE,
            alpha=1, legend=FALSE,
            col="#664DCC")
    }
    if (maskRockies && !plotWater) {
        plot(r_mask, add=TRUE, alpha=1,
            col="#7A8B8B", legend=FALSE)
    }
    if (plotWater && maskRockies) {
        plot(r_overlay, add=TRUE,
            alpha=1, legend=FALSE,
            col=colorRampPalette(c("#664DCC", "#7A8B8B"))(255))
    }

    if (plotCities) {
        points(city, pch=18, col="grey10")
        text(city, labels=rownames(city@coords), cex=0.8, pos=3, col="grey10")
    }
    invisible(r)
}

xy_map <-
function(xy, pa, plotWater=TRUE, legend=FALSE, main="",
pch0=3, pch1=19, cex0=0.3, cex1=0.8, col0="red1", col1="red4")
{

    xy <- rbind(xy[pa <= 0,], xy[pa > 0,])
    Found <- c(rep(FALSE, sum(pa <= 0)), rep(TRUE, sum(pa > 0)))

    coordinates(xy) <- ~ POINT_X + POINT_Y
    proj4string(xy) <- CRS("+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")
    xy <- spTransform(xy, CRS("+proj=tmerc +lat_0=0 +lon_0=-115 +k=0.9992 +x_0=500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"))

    plot(nr, axes=FALSE, box=FALSE, legend=legend, main=main,
        col=brewer.pal("Pastel1", n=6)[c(3,1,2,6,5,4)])
    if (plotWater)
        plot(r_water, add=TRUE, alpha=1, legend=FALSE, col="#664DCC")
    points(xy, pch=ifelse(Found, pch1, pch0),
        cex=ifelse(Found, cex1, cex0),
        col=ifelse(Found, col1, col0))
    invisible(xy)
}

normalize_data <-
function(rf, cr, q=1, transf=FALSE, normalize=TRUE)
{
    if (transf) {
        cr <- 1-exp(-cr)
        rf <- 1-exp(-rf)
    }
    ## truncate if necessary
    qcr <- quantile(cr, q, na.rm=TRUE)
    cr[cr>qcr] <- qcr
    qrf <- quantile(rf, q, na.rm=TRUE)
    rf[rf>qrf] <- qrf
    Max <- max(qcr, qrf)

    if (normalize) {
        #si <- pmin(cr, rf) / pmax(cr, rf)
        #si <- pmin(100, ceiling(99 * si)+1)
        #si2 <- ifelse(cr > rf, 200-si, si)
        df <- (cr-rf) / Max
        df <- sign(df) * abs(df)^0.5
        df <- pmin(200, ceiling(99 * df)+100)
        df[df==0] <- 1
        cr <- pmin(100, ceiling(99 * sqrt(cr / Max))+1)
        rf <- pmin(100, ceiling(99 * sqrt(rf / Max))+1)

        #data.frame(Ref=rf, Curr=cr, Diff=df, si=si, si2=si2)
        out <- data.frame(Ref=rf, Curr=cr, Diff=df)
    } else {
        cr <- round(100 * cr / Max)
        rf <- round(100 * rf / Max)
        out <- data.frame(Ref=rf, Curr=cr)
    }
    out
}
