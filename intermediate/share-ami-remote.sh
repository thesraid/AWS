#!/bin/bash

# joriordan

# Prints the script usage information
function usage
{
    echo "share-ami-remote [-h]
          --region [-r] REGION
         
          Shares the AMIs on the primary AV account with the subOrgs in this account.
 
          THIS COMMAND IS RUN REMOTELY ON THE SCRIPT SERVER AS IT HAS ACCESS TO THE AMIS
"
}

echo "This will not work on a Terminus SSH client due to a bug in Terminus"

# Read the input from the command.
while [ "$1" != "" ]; do
    case $1 in
        -r | --region )         shift
                                region=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

echo "Copying list of subOrgs to the scriptServer"
aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --output text --query 'Accounts[*].[Id]' > accounts.txt
scp accounts.txt ubuntu@script-server.alien-training.com:.johno/awscli/accounts.txt

ssh ubuntu@script-server.alien-training.com /home/ubuntu/.johno/awscli/share-ami.sh -r $region -s /home/ubuntu/.johno/awscli/accounts.txt
