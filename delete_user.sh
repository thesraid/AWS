#!/bin/bash
function usage
{
    echo "
usage: new_user.sh [-h]	--user_name [-u] USER_NAME
                        --group_name [-g] GROUP_NAME
                        --cl_profile_name [-c] CLI_PROFILE_NAME
"
}

userName=""
groupName=""
profile=""

while [ "$1" != "" ]; do
    case $1 in
        -u | --user_name )   	shift
                                userName=$1
                                ;;
        -g | --group_name ) 	shift
                                groupName=$1
                                ;;
        -c | --cl_profile_name ) shift
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

