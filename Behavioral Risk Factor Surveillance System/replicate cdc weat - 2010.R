# analyze survey data for free (http://asdfree.com) with the r language
# behavioral risk factor surveillance system
# 2010

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/BRFSS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/Behavioral%20Risk%20Factor%20Surveillance%20System/replicate%20cdc%20weat%20-%202010.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


######################################################################
# this script matches the web-enabled analysis tool output shown at  ################################################################################################################
# https://github.com/ajdamico/asdfree/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/WEAT%202010%20Asthma%20Status%20-%20Crosstab%20Analysis%20Results.pdf?raw=true #
#####################################################################################################################################################################################



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#########################################################################################################################################
# prior to running this analysis script, the brfss 2010 single-year file must be loaded as a monet database-backed survey object        #
# on the local machine. running the 1984-2011 download and create database script will create a monet database containing this file     #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://github.com/ajdamico/asdfree/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/download%20all%20microdata.R       #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# that script will create a file "b2010 design.rda" in C:/My Directory/BRFSS or wherever the working directory was set for the program  #
#########################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


library(survey)			# load survey package (analyzes complex design surveys)
library(DBI)			# load the DBI package (implements the R-database coding)
library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# uncomment this line by removing the `#` at the front..
# setwd( "C:/My Directory/BRFSS/" )


# the behavioral risk factor surveillance system download and importation script
# has already created a monet database-backed survey design object
# connected to the 2010 single-year table

# since this script only loads one file off of the local drive,
# there's no need to set the working directory.
# instead, simply use the full filepath to the r data file (.rda)
# as shown in the load() examples below.

# choose which single-year file in your BRFSS directory to analyze
# this script replicates the 2010 single-year estimates,
# so uncomment that line and the other three choices commented out.

# load the desired behavioral risk factor surveillance system monet database-backed complex sample design objects

# uncomment one of these lines by removing the `#` at the front..
load( 'b2010 design.rda' )	# analyze the 2010 single-year acs
# load( 'b2011 design.rda' )	# analyze the 2011 single-year acs
# load( 'b2009 design.rda' )	# analyze the 2009 single-year acs
# load( 'b1984 design.rda' )	# analyze the 1984 single-year acs

# note: this r data file should already contain the 2010 single-year design

# if you wnated to use an unedited version of this, you could simply #
# connect the complex sample designs to the monet database like this: #
brfss.d <- open( brfss.design , driver = MonetDB.R() )	# single-year design


# # # # # # # # # # # # # # # # #
# numeric-to-factor conversion  #

brfss.d <- update( brfss.d , xasthmst = factor( xasthmst ) )

# the 'asthma' column is coded as numeric 
# in the importation sas script for the 2010 brfss
# http://www.cdc.gov/brfss/annual_data/2010/sasout10.sas
# so that needs to be converted over to a factor.


#############################################################################
# ..and immediately start printing the statistics in the replication target #
#############################################################################

# https://github.com/ajdamico/asdfree/blob/master/Behavioral%20Risk%20Factor%20Surveillance%20System/WEAT%202010%20Asthma%20Status%20-%20Crosstab%20Analysis%20Results.pdf?raw=true #


# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )


# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )

	
# calculate unweighted sample size column #
dbGetQuery( 
	db , 
	'select 
		xasthmst , count(*) as sample_size 
	from 
		b2010 
	group by 
		xasthmst
	order by
		xasthmst'
)


###########################
# row percent replication #
###########################


# run the row and S.E. of row % columns
# print the row percent column to the screen
( row.pct <- svymean( ~xasthmst , brfss.d ) )

# extract the covariance matrix attribute from the svymean() output
# take only the values of the diagonal (which contain the variances of each value)
# square root them all to calculate the standard error
# save the result into the se.row.pct object and at the same time
# print the standard errors of the row percent column to the screen
# ( by surrounding the assignment command with parentheses )
( se.row.pct <- sqrt( diag( attr( row.pct , 'var' ) ) ) )

# confidence interval lower bounds for row percents
row.pct - qnorm( 0.975 ) * se.row.pct 

# confidence interval upper bounds for row percents
row.pct + qnorm( 0.975 ) * se.row.pct


####################################
# weighted sample size replication #
####################################

# run the sample size and S.E. of weighted size columns
# print the sample size (weighted) column to the screen
( sample.size <- svytotal( ~xasthmst , brfss.d ) )


# extract the covariance matrix attribute from the svymean() output
# take only the values of the diagonal (which contain the variances of each value)
# square root them all to calculate the standard error
# save the result into the se.sample.size object and at the same time
# print the standard errors of the weighted size column to the screen
# ( by surrounding the assignment command with parentheses )
( se.sample.size <- sqrt( diag( attr( sample.size , 'var' ) ) ) )

# confidence interval lower bounds for weighted size
sample.size - qnorm( 0.975 ) * se.sample.size 

# confidence interval upper bounds for weighted size
sample.size + qnorm( 0.975 ) * se.sample.size

# close the connection to the two survey design object
close( brfss.d )



# disconnect from the current monet database
dbDisconnect( db , shutdown = TRUE )

