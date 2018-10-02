#!/bin/bash

# joriordan

# Prints the script usage information
function usage
{
    echo "usage: loop.sh [-h]
                                      --array [-a] ARRAY
                                      --bbb [-b] BBB
                                      --ccc [-c] CCC"
}

# Read the input from the command.
while [ "$1" != "" ]; do
    case $1 in
        -a | --array )          shift
                                array=($1)
                                ;;
        -b | --bbb)             shift
                                bbb=$1
                                ;;
        -c | --ccc )            shift
                                ccc=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

echo $bbb
echo $ccc
#arr=($array)

# Iterate through each AWS region and remove any labs
for a in "${array[@]}"
do
   printf $a
   printf ","
done
printf "\n"
