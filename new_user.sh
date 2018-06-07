#!/bin/bash
function usage
{
    echo "
usage: new_user.sh [-h]	--user_name [-u] USER_NAME
		      	--password [-p] PASSWORD
                        --group_name [-g] GROUP_NAME
		      	--policy [-o] POLICY
		      	--region [-r] REGION
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
	-r | --region )         shift
                                region=$1
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
echo REG  : $region
echo POL  : $policy
echo PROF : $newProfile



printf "Creating a new user\n"
aws iam create-user --user-name $userName --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured creating a user\n"
  exit 1
fi

printf "Creating a new group\n"
aws iam create-group --group-name $groupName --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured creating a group\n"
  exit 1
fi

printf "Adding the user to the group\n"
aws iam add-user-to-group --user-name $userName --group-name $groupName --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured adding the user to the group\n"
  exit 1
fi

printf "Assigning policy to user\n"
aws iam put-group-policy --group-name $groupName --policy-name StudentRole --policy-document $policy --profile $newProfile
aws iam put-group-policy --group-name $groupName --policy-name LocationRole --policy-document file://$region.json --profile $newProfile
if [ $? -ne 0 ]
then
  printf "Error occured assigning the policy to the user\n"
  exit 1
fi

printf "Giving user a login password\n"
aws iam create-login-profile --user-name $userName --password $userPassword --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured setting the users login and password\n"
  exit 1
fi

