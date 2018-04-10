#!/bin/bash
function usage
{
    echo "
usage: new_user.sh [-h]	--user_name [-u] USER_NAME
		      	--password [-p] PASSWORD
                        --group_name [-g] GROUP_NAME
		      	--policy [-o] POLICY
                        --cl_profile_name [-c] CLI_PROFILE_NAME
"
}

userName=""
userPassword=""
groupName=""
policy=""
newProfile=""

while [ "$1" != "" ]; do
    case $1 in
        -u | --user_name )   	shift
                                userName=$1
                                ;;
        -p | --password)  	shift
                                userPassword=$1
                                ;;
        -g | --group_name ) 	shift
                                groupName=$1
                                ;;
        -o | --policy )        	shift
                                policy=$1
                                ;;
        -c | --cl_profile_name ) shift
                                newProfile=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$userName" = "" ] || [ "$userPassword" = "" ] || [ "$groupName" = "" ] || [ "$policy" = "" ] || [ "$newProfile" = "" ]
then
  usage
  exit
fi

echo USER : $userName
echo PASS : $userPassword
echo GRP  : $groupName
echo POL  : $policy
echo PROF : $newProfile



aws iam delete-user-policy --user-name $userName --policy-name StudentPowerUserRole --profile $newProfile
if [ $? -ne 0 ]
then
  printf "Error occured deleting a policy\n"
  exit 1
fi
printf "Removed policy from user\n"

aws iam remove-user-from-group --group-name $groupName --user-name $userName --profile $newProfile
if [ $? -ne 0 ]
then
  printf "Error occured removing the user from a group\n"
  exit 1
fi
printf "Removed user from group\n"

aws iam delete-group --group-name $groupName --profile $newProfile
if [ $? -ne 0 ]
then
  printf "Error occured deleting the group\n"
  exit 1
fi
printf "Deleted group\n"

aws iam delete-login-profile --user-name $userName --profile $newProfile
if [ $? -ne 0 ]
then
  printf "Error occured remving the users login permissions (profile) \n"
  exit 1
fi
printf "Removed user login permissions\n"

aws iam delete-user --user-name $userName --profile $newProfile
if [ $? -ne 0 ]
then
  printf "Error occured deleting the user\n"
  exit 1
fi
printf "Deleted user\n"

