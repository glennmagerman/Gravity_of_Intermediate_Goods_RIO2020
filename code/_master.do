* Version: April 2019
* Author: Glenn Magerman

// folder management
clear all
global folder 	"XXX" 								// create project folder on your own machine

global raw 		"$folder/data/raw"
global tmp		"$folder/data/tmp"
global clean 	"$folder/data/clean"
global results	"$folder/results"

// initialize folders
foreach dir in tmp clean results {
	cap !rm -rf "./`dir'"
}

// create task folders
foreach dir in raw tmp clean results {
	cap !mkdir "./`dir'"
}	

// panel dimensions
global start	1998
global end		2011


/* Install ado if needed
ssc install reghfde
ssc install ppmlhdfe
ssc install erepost
ssc install estout
*/

clear


