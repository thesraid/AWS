#!/bin/bash

# joriordan

# Prints the script usage information
function usage
{
    echo "verify-email-remote [-h]
          --start [-s] 10       First AVStudent Number
          --end [-e]   20       Last AVStudent Number

RUNS REMOTELY ON SCRIPT SERVER AS IT RUNS THE MAIL SERVER TO alien-training.com"
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

ssh ubuntu@script-server.alien-training.com /home/ubuntu/.johno/awscli/verify-email.sh -s $address -e $end
