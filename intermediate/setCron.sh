#!/bin/bash
# joriordan
# Prints the script usage information
function usage
{
    echo "setCron.sh [-h]
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

# Ensure a valid poweroff Timezone was selected
if [ "$zone" != "WET" ] && [ "$zone" != "CET" ] && [ "$zone" != "EST" ] && [ "$zone" != "PST" ] && [ "$zone" != "APJ" ] 
then
  echo "$zone is invalid. Choices are WET CET EST PST APJ"
  exit
fi

# Use a regex to ensure the poweroff date was inputted in the correct format
if [[ $powerOffDate =~ ^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$ ]]
then
   # Check if the date is a valid date and not something like 9999-99-99
   if [ -z "$(date -d $powerOffDate 2>/dev/null)" ]
   then
      echo "$powerOffDate is invalid. Dates should be in the format YYYY-MM-DD"
      exit
   fi
else
   echo "$powerOffDate is invalid. Dates should be in the format YYYY-MM-DD"
   exit
fi

# Ensure the poweroff date is in the future
if [ $(date +%s) -ge $(date -d $powerOffDate +%s) ]
then
   echo "$powerOffDate is not a future date"
   exit
fi

# Split the date into different variables
day=($(date -d $powerOffDate +"%d"))
month=($(date -d $powerOffDate +"%m"))
year=($(date -d $powerOffDate +"%y"))
echo "Irish Time : $day 19"

# Convert the date and time into Irish time (as the server is running in Ireland)
case $zone in
   WET )
      hour=19
      echo "WET : $day $hour"
      ;;
   CET )
      hour=20
      echo "CET : $day $hour"
      ;;
   EST )
      hour=00
      day=$((day+1))
      echo "EST : $day $hour"
      ;;
   PST )
      day=$((day+1))
      hour=03
      echo "PST : $day $hour"
      ;;
   APJ )
      day=$((day+1))
      hour=09
      echo "APJ : $day $hour"
      ;;
esac

# Add the cronjob and write the output of the cronjob to a log file
(crontab -l 2>/dev/null; echo "00 19 $day $month * /usr/bin/env bash /usr/local/bin/finishCourse -a cliaccount | tee -a /var/log/labs/startCourse.log") | crontab -
