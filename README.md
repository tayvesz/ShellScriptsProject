###Author
Yves ZANGO

###Syllabus
The project is a program written in the bash scripting language. This program should allow the user
to perform requests on a large CSV (Comma Separated Values) dataset file. This dataset reflects
reported incidents of crime that occurred in the City of Chicago from 2001 to present. Data is
extracted from the Chicago Police Department's CLEAR (Citizen Law Enforcement Analysis and
Reporting) system.
#Usage

###General information

**chicrimes.sh** allows performing some requests on a large CSV (Comma Separated Values) dataset file. This dataset reflects 
reported incidents of crime that occurred in the City of Chicago from 2001 to present. Data is extracted from the Chicago 
Police Department's CLEAR (Citizen Law Enforcement Analysis and Reporting) system.


First, you must make the shell executable by doing this command :  chmod +x chicrimes.sh

The usage is as follows:

```sh
chicrimes.sh [-f <dataset_file>] [options]                                       
                                                                                          
Options:

	-h Show basic help message and exit                                               
	-v Show program's authors and exit                                                
	-f <file> Path to the dataset file                                                
	-l Prints IDs, case numbers, dates, primary types, descriptions,                  
          blocks and GPS coordinates of crimes                                            
	-c Prints number of crimes                                                        
	-b Prints the adresse of crimes using Maps API                                    
	-r Prints the crime solving rate                                                  
	-t List all different primary types of crimes                                     
	-T <primarytype> Filter results on crimes where the primary type is <primarytype> 
	-d List all different descriptions of crimes                                      
	-D <description> Filter results on crimes where the description is <description>  
	-Y <year> Filter results on crimes which happened during year <year>              
	-A <yes|no> yes Filter results on crimes for which a person was arrested          
           no Filter results on crimes for which no one was arrested                      
	-K <yes|no> yes Filter indicates whether the crime is domestic-related            
           no Filter indicates that the crime is not domestic-related
```

###Description

The shell program needs :
	* input file (using the flag option -f), 
	* some optional filters which need an argument (e.g. -Y <year> Filter results on crimes which happened during year <year>
	* the specification of one or several actions (e.g. -r to print the solving rate)

* If any filter is specified in the command, first of all the shell program filters the input file and stores the filtered file
  in a temporary file which will be destroyed at the end of the entire program.
* Otherwise, if there is no filter the input file is directly used for the actions processes.

* Once the filtered file is obtained, the different action specified by the user are run.


###Additional information

1. In the shell we used for filter processes and other tasks awk command. The field separator used is FS=",".However to deal 
   with comma embedded in some fields which is the case of description field using FPAT = "([^,]*)|(\"[^\"]+\")" a regular expression
   which splits either by a comma or by a double quotes according the context. FPAT requires the installation of GAWK (on ubuntu: sudo apt-get install gawk) 
   The usage of FPAT increase the runtime

   As example when **FPAT="([^,]*)|(\"[^\"]+\")"** is used the command **chicrimes.sh -f Crimes_-_2001_to_present.csv -r** is performed in 210 seconds on a computer 
   which has a RAM of 24 Gb and 250 seconds on a PC with 8 GB RAM. 
   However the result is more precise (28.48%)
   A contrario, if we use **FS=","** the runtime of the same command is less high (19s and 59s respectively with 24 GB RAM and 8GB RAM).
   Moreover the result is not exact because some records are wrong due to bad splitting process (the result of the command is 27.58%)
   *Yout will find in the folder the two version of chicrimes.sh : (ychicrimes.sh the version using FPAT and chicrimes.sh the version which uses just FS=",")*

2. The action (-b) which computes the addresses of crimes requires a connexion to the internet and use cURL command and **Google Maps Api**.

3. The terminal windows must be at its maximal size to display properly the colors of results
