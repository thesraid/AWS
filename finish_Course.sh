#!/bin/bash
function usage
{
    echo "usage: finish_Course.sh [-h]
				      --region [-r] REGION 
				      --account_name [-a] ACCOUNT_NAME"
}

accName=""

while [ "$1" != "" ]; do
    case $1 in
        -a | --account_name )   shift
                                accName=$1
                                ;;
	-r | --region )		shift
				region=$1
				;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$accName" = "" ]
then
  aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[*].Name' 
  printf "Please enter the name of the account (with or without quotes) : "
  read accName
  # Remove quotes if entered
  accName=$(sed -e 's/^"//' -e 's/"$//' <<< $accName)
  printf "You chose $accName \n"
fi

accID=$(aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[?Name==`'$accName'`].Id' --output text)
if [ "$accID" = "" ] 
then
   printf "Invalid account\n"
   exit
fi
printf "The account ID for $accName is $accID\n"

profile=$accName"Profile"
userName=$accName
groupName=$accName

if [ "$region" = "" ]
then
   printf "\nAvailable Regions\n"
   printf "   eu-west-1\n"
   printf "   us-east-1\n"
   printf "\n"
   printf "Please choose a region : "
   read region
   region=$(sed -e 's/^"//' -e 's/"$//' <<< $region)
   printf "You chose $region\n"
fi

if [ "$region" != "eu-west-1" ] && [ "$region" != "us-east-1" ]
then
   printf "Invalid region\n"
   exit
fi

aws configure set region $region --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi

INSTANCES=($(aws ec2 describe-instance-status --query InstanceStatuses[*].InstanceId --output text --profile $profile))


INSTANCES_STRING=""
for i in "${INSTANCES[@]}"
do
   INSTANCES_STRING+=" $i"
done

if [ -n "$INSTANCES_STRING" ]
then
   printf "\nTerminating Instances"
   aws ec2 terminate-instances --instance-ids $INSTANCES_STRING --profile $profile
   if [ $? -ne 0 ]
   then
     printf "FAILED to terminate all Instancese\n"
     exit 1
   fi

   # Give instances time to shut down - This should really be iplemented to wait until all instances show as terminated
   sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "."
   sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "."
   sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf ".\n"
fi

STACKS=($(aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile $profile))

for STACK in "${STACKS[@]}"
do

   printf "\nDeleting $STACK \n"
   aws cloudformation delete-stack --stack-name $STACK --profile $profile
   if [ $? -ne 0 ]
   then
     printf "$STACK FAILED to Delete\n"
     exit 1
   fi

   printf "Waiting for $STACK to delete ..."
   cfStat=$(aws cloudformation describe-stacks --stack-name $STACK --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
   while [ "$cfStat" = "DELETE_IN_PROGRESS" ]
   do
     sleep 5
     printf "."
     cfStat=$(aws cloudformation describe-stacks --stack-name $STACK --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
     if [ "$cfStat" = "DELETE_FAILED" ]
     then
       printf "\n$STACK FAILED to delete\n"
       printf "MANUAL CLEANUP REQUIRED\n"
       exit 1
     fi
   done
   printf "An error occurred (ValidationError) when calling the DescribeStacks operation: Stack with id $STACK does not exist << IGNORE THIS ERROR IF SEEN ABOVE\n"
   printf "\n$STACK deleted\n"
done

KEYS=($(aws ec2 describe-key-pairs --query KeyPairs[*].KeyName --output text --profile $profile))

printf "\nDeleting Keys\n"

for KEY in "${KEYS[@]}"
do
	aws ec2 delete-key-pair --key-name $KEY --profile $profile
	if [ $? -ne 0 ]
   	then
     		printf "$KEY FAILED to Delete\n"
   	fi
done

aws iam delete-user-policy --user-name $userName --policy-name StudentRole --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured deleting a policy\n"
  exit 1
fi
printf "Removed policy from user\n"

aws iam remove-user-from-group --group-name $groupName --user-name $userName --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured removing the user from a group\n"
  exit 1
fi
printf "Removed user from group\n"

aws iam delete-group --group-name $groupName --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured deleting the group\n"
  exit 1
fi
printf "Deleted group\n"

aws iam delete-login-profile --user-name $userName --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured remving the users login permissions (profile) \n"
  exit 1
fi
printf "Removed user login permissions\n"

aws iam delete-user --user-name $userName --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured deleting the user\n"
  exit 1
fi
printf "Deleted user\n"

