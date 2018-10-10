#!/bin/bash

# joriordan

# Prints the script usage information
function usage
{
    echo "add2Array [-h]
          --start [-s] 10       First AVStudent Number
          --end [-e]   20       Last AVStudent Number"
}

# Read the input from the command.
while [ "$1" != "" ]; do
    case $1 in
        -s | --start )          shift
                                address=$1
                                ;;
        -e | --end )            shift
                                end=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

ARRAY=()
end=$[$end+1]

while [ $address -lt $end ]
do
   #echo $address
   ARRAY+=($address)
   address=$[$address+1]
done

printf '%s\n' "${ARRAY[@]}"
