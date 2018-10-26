#!/bin/bash
# joriordan
# Prints the script usage information
function usage
{
    echo "powerOff.sh [-h]
                                      --date [-d] DATE                  Date to power off YYYY-MM-DD
                                      --timezone [-z] TIMEZONE          WET CET EST PST APJ"
}


# Read the input from the command.
while [ "$1" != "" ]; do
    case $1 in
        -d | --date )           shift
                                powerOffDate=$1
                                ;;
        -z | --timezone )       shift
                                zone=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$zone" != "WET" ] && [ "$zone" != "CET" ] && [ "$zone" != "EST" ] && [ "$zone" != "PST" ] && [ "$zone" != "APJ" ] 
then
  echo "$zone is invalid. Choices are WET CET EST PST APJ"
  exit
fi

if [[ $powerOffDate =~ ^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$ ]]
then
   if [ -z "$(date -d $powerOffDate 2>/dev/null)" ]
   then
      echo "$powerOffDate is invalid. Dates should be in the format YYYY-MM-DD"
      exit
   fi
else
   echo "$powerOffDate is invalid. Dates should be in the format YYYY-MM-DD"
   exit
fi

#echo "Date : $powerOffDate"
#echo "TZ   : $zone"

day=($(date -d $powerOffDate +"%d"))
month=($(date -d $powerOffDate +"%m"))
year=($(date -d $powerOffDate +"%y"))
echo " You entered $year-$month-$day"
#echo " "
echo "Date is $(date -d $powerOffDate)"
newDate=$(date -d $powerOffDate+"1 days")
echo "Next is $newDate"

day=($(date -d "$newDate" +"%d"))
month=($(date -d "$newDate" +"%m"))
year=($(date -d "$newDate" +"%y"))

echo "Year:  $year"
echo "Month: $month"
echo "Day:   $day"


#(crontab -l 2>/dev/null; echo "45 08 23 10 * finishCourse -a cliaccount") | crontab -
