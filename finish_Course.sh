#!/bin/bash
function usage
{
    echo "usage: finsih_Course.sh [-h] 
				      --account_name [-a] ACCOUNT_NAME"
}

accName=""

while [ "$1" != "" ]; do
    case $1 in
        -a | --account_name )   shift
                                accName=$1
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


printf "\nDeleting Lab Under Account\n"
aws cloudformation delete-stack --stack-name VPC --profile cliaccount
if [ $? -ne 0 ]
then
  printf "Student Lab FAILED to Delete\n"
  exit 1
fi

printf "Waiting for Student Lab to delete ..."
cfStat=$(aws cloudformation describe-stacks --stack-name VPC --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
while [ "$cfStat" = "DELETE_IN_PROGRESS" ]
do
  sleep 5
  printf "."
  cfStat=$(aws cloudformation describe-stacks --stack-name VPC --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
  if [ "$cfStat" = "DELETE_FAILED" ]
  then
    printf "\nStudent Lab FAILED to delete\n"
    printf "MANUAL CLEANUP REQUIRED\n"
    exit 1
  fi
done
printf "Any errors above regarding the VPC no longer being present is due to the deletion and can be ignored\n"
printf "\nStudent Lab VPC deleted\n"


aws iam delete-user-policy --user-name $userName --policy-name StudentPowerUserRole --profile $profile
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
