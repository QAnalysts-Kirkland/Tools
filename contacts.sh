#!/bin/bash          

# This script allows the user to create any number of contacts from the command line
# I.e 
# "./contacts.sh 10" Will output 10 contacts in standard .vcf form

# Better use of this script is to redirect the output using >  
#I.e
# "./contacts.sh 10 > test.vcf" will create a .vcf file with 10 contacts

	    declare -i c
	    for (( c=1; c<=$1; c++ ))
            do
	       echo "BEGIN:VCARD"
               echo "VERSION:4.0"
	       echo "n:Last name;Name$c;;;;"
               echo "fn:Name$c Last name"
	       echo "adr;type=current:;;Street;City;;zip;Country"
	       echo "END:VCARD"
	    done
      
	    