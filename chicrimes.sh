
#!/bin/bash 

# Initialization of Runtime computation variable
START=$(date +%s)

# Usage function which explains how to use the script and shows the differents options
# For printing colors we use tput command
function usage() { 
	echo "$(tput setab 4)$(tput bold)                                                                                          $(tput sgr 0)"
	echo "$(tput setab 4)$(tput bold)  Usage: chicrimes.sh [-f <dataset_file>] [options]                                       $(tput sgr 0)"
	echo "$(tput setab 4)$(tput bold)                                                                                          $(tput sgr 0)"
	echo "$(tput setab 0)$(tput bold) Options:									          $(tput sgr 0)"
	echo 	"$(tput setab 0)	-h Show basic help message and exit                                               $(tput sgr 0)"
	echo	"$(tput setab 0)	-v Show program's authors and exit                                                $(tput sgr 0)"
	echo	"$(tput setab 0)	-f <file> Path to the dataset file                                                $(tput sgr 0)"
	echo	"$(tput setab 0)	-l Prints IDs, case numbers, dates, primary types, descriptions,                  $(tput sgr 0)"
	echo "$(tput setab 0)          blocks and GPS coordinates of crimes                                            $(tput sgr 0)"
	echo	"$(tput setab 0)	-c Prints number of crimes                                                        $(tput sgr 0)"
	echo	"$(tput setab 0)	-b Prints the adresses of crimes using Maps API                                    $(tput sgr 0)"
	echo	"$(tput setab 0)	-r Prints the crime solving rate                                                  $(tput sgr 0)"
	echo	"$(tput setab 0)	-t List all different primary types of crimes                                     $(tput sgr 0)"
	echo	"$(tput setab 0)	-T <primarytype> Filter results on crimes where the primary type is <primarytype> $(tput sgr 0)"
	echo	"$(tput setab 0)	-d List all different descriptions of crimes                                      $(tput sgr 0)" 
	echo	"$(tput setab 0)	-D <description> Filter results on crimes where the description is <description>  $(tput sgr 0)"
	echo	"$(tput setab 0)	-Y <year> Filter results on crimes which happened during year <year>              $(tput sgr 0)"
	echo	"$(tput setab 0)	-A <yes|no> yes Filter results on crimes for which a person was arrested          $(tput sgr 0)"
	echo "$(tput setab 0)           no Filter results on crimes for which no one was arrested                      $(tput sgr 0)"
	echo	"$(tput setab 0)	-K <yes|no> yes Filter indicates whether the crime is domestic-related            $(tput sgr 0)"
	echo "$(tput setab 0)           no Filter indicates that the crime is not domestic-related                     $(tput sgr 0)"
	echo
	exit
}

function display_author(){

	# Function which display the script author's name
	echo
	echo "$(tput setab 4)                                     $(tput sgr 0)"
	echo "$(tput setab 4)  The program's author is $(tput bold)Yves ZANGO $(tput sgr 0)"
	echo "$(tput setab 4)                                     $(tput sgr 0)"
	echo
	exit
}


############################################ Actions ####################################################
	 
# In the following functions "tail -n +2" is used to skip the first line (header) of the input file
# The field separtor is FS=",". However to deals with comma embedded in some fields which is the case of
# description field using FPAT = "([^,]*)|(\"[^\"]+\")" which is a regular expression allowing to split  
# either by a comma or by a double quotes.
# FPAT requires the installation of GAWK. We tested it for a medium size of csv file but for the the
# initial csv file the computation time is very long. Hence we decided to keep FS="," as Field Separator 

function primary_type_list(){

	# This function prints the list of all primary types which are in column 6
	# It takes as parameter "$1" which is the input file (or filtered file the output of filter function)
	# It returns a temporary files which is used to display the primary types list using a cat command
	
	infile="$1"
	awk  'BEGIN{FS=","}
		{	
			print $6
		}' "$infile" | tail -n +2 | sort | uniq

}	

function description_list(){

	# This function prints the list of all descriptions which are in column 7
	# It takes as parameter "$1" which is the input file (or filtered file the output of filter function)
	# It returns a temporary files which is used to display the descriptions list using a cat command
	
	infile="$1"
	awk  'BEGIN{FS=","}
		{	
			print $7
		}' "$infile" | tail -n +2 | sort | uniq

}

function number_of_crimes(){

	# This function computes the number of crimes which is the number of line in 
	# the input file (or filtered file the output of filter function)
	
	infile="$1"
     local nbcrimes=$(cat $infile | tail -n +2 | wc -l)
     echo $nbcrimes
}

function solving_rate(){

	# This functions computes the rate of crimes resolved of the input file 
	# (or filtered file the output of filter function)
	# This correspons to the crimes where the value of column 9 ("Arrested") equals "true")
	# with a precision of two decimal places
	
	infile=$1

	
	nb_resolved=$(awk 'BEGIN{FS=","}
		{if ($9=="true")
				print $9
		}' "$infile" |wc -l)

	
	if [ $(number_of_crimes $infile) -ne 0 ]; then

		local solve_rate=$(echo "scale=2 ; $nb_resolved * 100/ "$(number_of_crimes $infile) | bc)
		echo $solve_rate" %"
	fi
}

function l_option_function(){

	# This function prints the following fields of the input or filtered file
	# IDs = 1, case numbers = 2, dates = 3,blocks = 4 , primary type = 6, 
	# descriptions = 7, GPS coordinates of crimes lat:20, long:21
	# It returns a temporary files which is used to display the descriptions list using a cat command

	infile="$1"	
	awk  'BEGIN{FS=","; OFS=", "}
		{	
			print $1, $2, $3, $4, $6, $7, $20, $21
		}' "$infile"  | tail -n +2

}

function get_address(){
	# This function prints the addresses based on google MAPS API
	# It uses as parameter an input file (filtered file) and call a the API of google using CURL command 
	# This command takes as parameters the longitude and lattitude of the crime obtained using a cut command
	# It returns a temporary files which is used to display the descriptions list using a cat command
	

	infile="$1"


	# Storing the GPS cordinate into a temporary file /tmp/v1. This file will contain two fields (longitude and latitude) separated by a comma
	awk -F"," 'NR > 1 {print $20, $21}' $infile > /tmp/v1

	# Applying the Curl command with the Maps API
	IFS=$'\n'       # New line is the only separator
	for line in $(cat /tmp/v1);do
		lat=$(cut -d' ' -f1 <<< $line)       	# Getting the value of Latitude
		lon=$(cut -d' ' -f2 <<< $line)		# Getting the value of Longitude

		# Several line of CURL result starts with "<formatted_address>", 
		# We kept just the first one which contains the essential information of the global address format. Then use cut function 
		# to get the string between the starter and ender tags <formatted_address> "addresse" <formatted_address>
		curl -s "http://maps.googleapis.com/maps/api/geocode/xml?latlng="$lat","$lon"&sensor=false" | grep "<formatted_address>"|head -1 | cut -d">" -f2 |cut -d"<" -f1 >>/tmp/v3
	done
	echo "/tmp/v3"
}

function no_action_specified(){
	echo
	echo "$(tput bold)$(tput setab 1)         Please check your options and write a command based on the usage presented below.        $(tput sgr 0)"
	echo "$(tput bold)$(tput setab 1) You must specify at least an input file and one action as presented in the usage function below  $(tput sgr 0)"
	echo 
	usage
	exit 1
}


############################## Implementation of filters ################################

	
function filter(){

	# This function runs the differents filters specified by the options
	# It takes as parameters the input file and a variable for the different filters 
	# It returns either the input file if none of the filter options is specified  
	# Otherwise, it returns a temporary files which contains the filtered file
	
	infile="$1"
	t="$2" 
	d="$3"
	y="$4"
	ar="$5"
	dom="$6"

	
	# If filter arguments are empty, replace by regex ".*" which means that character is matched
	# tr '[:lower:]' '[:upper:]' allows the matching to be non sensitive case

	if [ -z "$t" ]; then
		t=".*"
	else
		t=$(echo "^$2$" | tr '[:lower:]' '[:upper:]')
	fi

	if [ -z "$d" ]; then
		d=".*"
	else
		d=$(echo "^$3$" | tr '[:lower:]' '[:upper:]')
	fi
	
	if [ -z "$y" ]; then
		y=".*"
	else
		y=$(echo "^$4$" | tr '[:lower:]' '[:upper:]')
	fi
	
	# In the case of option Arrested, in the file Yes and No are respectively recorded as "True" and "False"
	if [ -z "$ar" ]; then
		ar=".*"
	elif [ $ar = "yes" ]; then
		ar="^true$"
	elif [ $ar = "no" ]; then
		ar="^false$"
	fi
	# In the case of option Domestic, in the file Yes and No are respectively recorded as "True" and "False"
	if [ -z "$dom" ]; then
		dom=".*"
	elif [ $dom = "yes" ]; then
		dom="^true$"
	elif [ $dom = "no" ]; then
		dom="^false$"
	fi
	
	# If no filter is specified, then do not run, return just the input file
	
	if [ "$t" = ".*" -a "$d" = ".*" -a "$y" = ".*" -a "$ar" = ".*" -a "$dom" = ".*" ]; then
		awk -v type="$t" -v desc="$d" -v year="$y" -v arr="$ar" -v domes="$dom" 'BEGIN {FS=","}
			{print}' "$infile"
	else
	# Else, run the filter but keep the first line (header)
			
		awk -v type="$t" -v desc="$d" -v year="$y" -v arr="$ar" -v domes="$dom" 'BEGIN {FS=","}
			{	
				if(NR==1 || $6 ~ type && $7 ~ desc && $18 ~ year && $9 ~ arr && $10 ~ domes)
					print
			}' "$infile"
	fi
}

#########################################################################################################################
####### Input file, Filter options arguments and actions variables intialization  #######################################


f_in=""							# input file argument variable
f_desc=""							# argument of the description filter option
f_type=""							# argument of the type filter option
f_year=""							# argument of the year filter option
f_arrested=""						# argument of the arrested filter (yes|no) option
f_domestic=""						# argument of the domestic-related filter (yes|no) option
list_t="";						# variable of the function which prints all the different primary types
list_d="";						# variable of the function which prints all the descriptions
nb_crimes="";						# variable of the function which computes the number of crimes
print_inf="";						# variable of the function which prints some informations (ID, Blocks, etc.)
s_rate="";						# variable of the function which computes the solving rate 
g_ad="";							# variable of the function which computes the adresses using MAPS Api 


# The variable of options which need an argument (filters) will take the value the argument provided by the user
# The variable of the other options (actions variables) will take "y" like "yes" to indicate their presence in the command 

################       Options Parsing       #############################################################################

# The option string start with ":" to be able to control/customize error messages

while getopts ":hvf:lbcrtT:dD:Y:A:K:" flag
do
	case $flag in

		f)
			f_in=$OPTARG;;
		h) 
			usage;;
		v)
			display_author;;
		D)
			f_desc=$OPTARG;;
		T) 
			f_type=$OPTARG;;
		Y)
			f_year=$OPTARG;;
		A)
			f_arrested=$OPTARG;;
		K)
			f_domestic=$OPTARG;;
		t)
			list_t="y";;
		l)
			print_inf="y";;
		d)
			list_d="y";;
		c)
			nb_crimes="y";;
		r)
			s_rate="y";;
		b)   
			g_ad="y";;
		\?)

			no_action_specified;;
	esac
done

shift "$(($OPTIND-1))"



## Checking the input file. Print some message in case of mistakes in the command or when a bad input is provided

if [ "$f_in" = "" ]; then
	echo
	echo "$(tput bold)$(tput setab 1) There is no input file in your command. Please check the usage function below $(tput sgr 0)"
	echo
	usage
fi

if [ ! -e "$f_in" ]; then
	echo
	echo "$(tput bold)$(tput setab 1) The File \"$f_in\" does not exist. Please check the path and/or the name of your file $(tput sgr 0)"
	echo
	exit
fi

#### Checking if any action is specified Processing ##############################################################################################

# If none of the different actions is specified in the command, consequently, the filter function is not call and a message using explains to the
# user that he must provide at least one action.

if [ "$list_t" = "" -a "$list_d" = "" -a "$print_inf" = "" -a "$nb_crimes" = "" -a "$s_rate" = "" -a "$g_ad" = "" ]; then
	no_action_specified
else
	# Else, the filter function is apply to the input file with the different filter arguments
	# The output of the function is redirected towards a temporary file /tmp/filtered_file which will be used for the differents actions processes
	filter "$f_in" "$f_type" "$f_desc" "$f_year" "$f_arrested" "$f_domestic" > /tmp/filtered_file
fi

#### Checking  if the filtered file is empty (contains just the header) before any action ##########################################################
# If the filtered file is empty, which is due to the fact that your filter does not generate any match
# Hence print a message to explain the context and none action is performed on the filtered file

if [[ $(wc -l < /tmp/filtered_file) -le 1 ]];then
	echo
	echo "$(tput bold)$(tput setab 1) Your filter does not match any crime in the input file. Please choose other arguments for your filters $(tput sgr 0)"
	echo
	exit
fi

################### If some additional unknown options are specified print usage function#########################################################
if [ -n "$*" ]; then

	echo
	echo "$(tput bold)$(tput setab 1)        You set some additional unknown options \"$*\". Please check the usage below      $(tput sgr 0)"
	echo 

	usage
fi


##### If the filtered file is not empty and an action is specified (which that the correspondig variable equals "y" ###############################
########################## Actions Processing #####################################################################################################

if [ -n "$list_t" ];then
	echo 
	echo "$(tput bold)$(tput setab 4) The list of all different primary types is presented below $(tput sgr 0)"
	primary_type_list /tmp/filtered_file
	echo
fi

if [ -n "$print_inf" ];then
	echo
	echo 
	echo "$(tput bold)$(tput setab 4) ID, case numbers, dates, primary types, descriptions,blocks and GPS coordinates of crimes is presented below. $(tput sgr 0)"
	echo "$(tput bold)$(tput setab 4)                 The First row is the name of each column and the field separator is "\",\""     	               $(tput sgr 0)"
	l_option_function /tmp/filtered_file
	echo
fi
		
if [ -n "$list_d" ];then
	echo
	echo "$(tput bold)$(tput setab 4) The list of all different descriptions is presented below $(tput sgr 0)"
	description_list /tmp/filtered_file
	echo
fi
		
if [ -n "$nb_crimes" ];then
	echo 
	echo "$(tput bold)$(tput setab 4)The number of crimes corresponding to your filter is "$(number_of_crimes /tmp/filtered_file)   "$(tput sgr 0)"
	echo
fi

if [ -n "$s_rate" ];then
	echo
	echo "$(tput bold)$(tput setab 4)The crime solving rate corresponding to your filter is "$(solving_rate /tmp/filtered_file)      "$(tput sgr 0)"
	echo
fi


if [ -n "$g_ad" ];then
	# Since the get_address function used curl command which requires a connection to internet
	# First, we must check the internet connexion status
	if ! ping -q -c 1 -W 1 8.8.8.8 > /dev/null 2>&1  ; then
		echo
		echo "$(tput bold)$(tput setab 1)    You do not have a connexion to internet to get the addresses    $(tput sgr 0)"
		echo "$(tput bold)$(tput setab 1) Indeed the function used curl which requires an internet connexion $(tput sgr 0)"
		echo

		exit
	else
		echo "$(tput bold)$(tput setab 4) The addresses of crimes corresponding to your filter are presented below  $(tput sgr 0)"
		cat $(get_address /tmp/filtered_file)
	fi
fi
########### Removing the tempory files generated during the previous processes ###########################################################

[ -e /tmp/v1 ] && rm /tmp/v1
[ -e /tmp/v2 ] && rm /tmp/v2
[ -e /tmp/v3 ] && rm /tmp/v3
[ -e /tmp/filtered_file ] && rm /tmp/filtered_file

####################  Runtime estimation ##########################################################################################################
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "$(tput bold)$(tput setab 4)It took $DIFF seconds 	$(tput sgr 0)"
