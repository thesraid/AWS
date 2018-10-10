#!/bin/bash
function usage
{
    echo "
usage: removeAdmin.sh [-h]	--account [-a] ACCOUNT
"
}

userName="AVAdmin"
groupName="AVAdmin"
profile=""

while [ "$1" != "" ]; do
    case $1 in
        -a | --account )   	shift
                                profile=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$userName" = "" ] || [ "$groupName" = "" ] || [ "$profile" = "" ]
then
  usage
  exit
fi

echo USER : $userName
echo GRP  : $groupName
echo PROF : $profile



#aws iam delete-user-policy --user-name $userName --policy-name StudentRole --profile $profile
aws iam delete-group-policy --group-name $groupName --policy-name StudentRole --profile $profile
#aws iam delete-group-policy --group-name $groupName --policy-name LocationRole --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured deleting a policy\n"
fi
printf "Removed policy from user\n"

aws iam remove-user-from-group --group-name $groupName --user-name $userName --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured removing the user from a group\n"
fi
printf "Removed user from group\n"

aws iam delete-group --group-name $groupName --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured deleting the group\n"
fi
printf "Deleted group\n"

aws iam delete-login-profile --user-name $userName --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured removing the users login permissions (profile) \n"
fi
printf "Removed user login permissions\n"

aws iam delete-user --user-name $userName --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured deleting the user\n"
fi
printf "Deleted user\n"

