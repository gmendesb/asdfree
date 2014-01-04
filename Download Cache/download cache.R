# written by http://hannes.muehleisen.org/

# from http://stackoverflow.com/questions/16474696/read-system-tmp-dir-in-r
gettmpdir <- 
	function() {
		tm <- Sys.getenv(c('TMPDIR', 'TMP', 'TEMP'))
		d <- which(file.info(tm)$isdir & file.access(tm, 2) == 0)
		if (length(d) > 0)
		  tm[[d[1]]]
		else if (.Platform$OS.type == 'windows')
		  Sys.getenv('R_USER')
		else '/tmp'
	}


# almost base64 encoding for plain R, no null padding and no padding markers
# <hannes@muehleisen.org>, 2014-01-04
almostbase64encode <- 
	function( someobj ) {
      stopifnot(length(someobj) == 1)
      stopifnot(nchar(someobj) > 0)
      
      somestr <- as.character(someobj)
      while (nchar(somestr) %% 3 != 0) {
        somestr <- paste0(somestr,"_")
      }  
      starts <- seq(1,nchar(somestr),by=3)
      pieces <- sapply(starts, function(ii) {
        substr(somestr, ii, ii+2)
      })  
      b46c <- "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
      return(paste0(sapply(pieces,function(piece) {
        n <- bitwShiftL(as.integer(charToRaw(substr(piece,1,1))),16) + 
          bitwShiftL(as.integer(charToRaw(substr(piece,2,2))),8) +
          as.integer(charToRaw(substr(piece,3,3)))
        n1 <- bitwAnd(bitwShiftR(n,18),63)+1
        n2 <- bitwAnd(bitwShiftR(n,12),63)+1
        n3 <- bitwAnd(bitwShiftR(n,6),63)+1
        n4 <- bitwAnd(n,63)+1
        paste0(substring(b46c,n1,n1),substring(b46c,n2,n2),substring(b46c,n3,n3),substring(b46c,n4,n4))
      }),collapse=""))  
    }




download.cache <- 
  function (
	url ,
	
	destfile ,
	
	# pass in any other arguments needed for the FUN
	... ,

	# specify which download function to use.
	# `download.file` and `downloader::download` should both work.
	FUN = download.file ,

	# if usedest is TRUE, then 
	# the program checks whether the destination file is present and contains at least one byte
	# and if so, doesn't do anything.
    usedest = FALSE , 
	
    # if usecache is TRUE, then
	# it checks the temporary directory for a file that has already been downloaded,
	# and if so, copies the cached file to the destination file *instead* of downloading.
	usecache = TRUE
	
  ) {
    		
		cat(
			paste0(
				"Downloading from URL '" ,
				url , 
				"' to file '" , 
				destfile , 
				"'... "
			)
		)
		
		if ( usedest && file.exists( destfile ) && file.info( destfile )$size > 0 ) {
		
			cat("Destination already exists, doing nothing (override with usedest=FALSE parameter)\n")
			
			return( invisible( 0 ) )
			
		}
		
		cachefile <- 
			paste0(
				gettmpdir() , 
				almostbase64encode( url ) , 
				".Rdownloadercache"
			)
		
		if (usecache) {
		
			if (file.exists(cachefile) && file.info(cachefile)$size > 0) {
				
				cat(
				  paste0(
					"Destination cached in '" , 
					cachefile , 
					"', copying locally (override with usecache=FALSE parameter)\n"
				  )
				)
				
				return (invisible(ifelse(file.copy(cachefile,destfile),0,1)))
				
		  }
		  
		}
		
		success <- 
			do.call( 
				FUN , 
				list( url , destfile , ... ) 
			) == 0
		
		if (success && usecache) file.copy( destfile , cachefile )
		
		return( invisible( success ) )
		
	}