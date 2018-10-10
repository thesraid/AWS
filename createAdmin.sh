#!/bin/bash
function usage
{
    echo "
usage: createAdmin.sh [-h]	--password [-p] PASSWORD
                                --account [-a] AVStudentXX
"
}

userName="AVAdmin"
userPassword=""
groupName="AVAdmin"
policy="file://policies/AdminPolicy.json"

while [ "$1" != "" ]; do
    case $1 in
        -p | --password)  	shift
                                userPassword=$1
                                ;;
        -a | --account )        shift
                                profile=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$userPassword" = "" ] || [ "$profile" = "" ]
then
  usage
  exit
fi

accID=$(aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[?Name==`'$profile'`].Id' --output text)
echo "USER : $userName"
echo "PASS : $userPassword"
echo "ACC  : $profile"
echo "ID   : $accID"


printf "Creating a new user\n"
aws iam create-user --user-name $userName --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured creating a user\n"
  exit 1
fi

printf "Creating a new group\n"
aws iam create-group --group-name $groupName --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured creating a group\n"
  exit 1
fi

printf "Adding the user to the group\n"
aws iam add-user-to-group --user-name $userName --group-name $groupName --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured adding the user to the group\n"
  exit 1
fi

printf "Assigning policy to user\n"
aws iam put-group-policy --group-name $groupName --policy-name StudentRole --policy-document $policy --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured assigning the policy to the user\n"
  exit 1
fi

printf "Giving user a login password\n"
aws iam create-login-profile --user-name $userName --password $userPassword --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured setting the users login and password\n"
  exit 1
fi

