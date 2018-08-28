#!/bin/bash
function usage
{
    echo "
usage: new_user.sh [-h] --cl_profile_name [-c] CLI_PROFILE_NAME
"
}

profile=""

while [ "$1" != "" ]; do
    case $1 in
        -c | --cl_profile_name ) shift
                                profile=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$profile" = "" ]
then
  usage
  exit
fi

echo PROF : $profile

# ITERATE THROUGH GROUPS
# REMOVE POLICIES FROM GROUP
# REMOVE USERS FROM GROUP
# REMOVE GROUP
# ITERATE THROUGH USERS
# REMOVE POLICIES FROM USER
# REMOVE LOGIN PROFILE
# REMOVE USER

printf "\n"
USERGROUPS=($(aws iam list-groups --output text --query 'Groups[*].GroupName' --profile $profile))
for group in "${USERGROUPS[@]}"
do
   printf "\nThis is group $group\n"
   GROUPPOLICIES=($(aws iam list-group-policies --output text --query 'PolicyNames[*]' --group-name $group --profile $profile))
   for policy in "${GROUPPOLICIES[@]}"
   do
      printf "Deleting policy $policy\n"
      aws iam delete-group-policy --group-name $group --policy-name $policy --profile $profile
   done
   USERS=($(aws iam get-group --group-name $group --query 'Users[*].UserName' --output text --profile $profile))
   for user in "${USERS[@]}"
   do
      printf "Removing $user from $group\n"
      aws iam remove-user-from-group --group-name $group --user-name $user --profile $profile
   done
   printf "Deleting $group\n"
   aws iam delete-group --group-name $group --profile $profile
done

USERS=($(aws iam list-users --output text --query 'Users[*].UserName' --profile $profile))
for user in "${USERS[@]}"
do
   USERPOLICIES=($(aws iam list-user-policies --output text --query 'PolicyNames[*]' --user-name $user --profile $profile))
   for policy in "${USERPOLICIES[@]}"
   do
      printf "Removing policy $policy from $user\n"
      aws iam delete-user-policy --user-name $user --policy-name $policy --profile $profile
   done
   printf "Deleting user: $user\n"
   aws iam delete-login-profile --user-name $user --profile $profile
   aws iam delete-user --user-name $user --profile $profile
done


##aws iam delete-user-policy --user-name $userName --policy-name StudentRole --profile $profile
#aws iam delete-group-policy --group-name $groupName --policy-name StudentRole --profile $profile
#aws iam delete-group-policy --group-name $groupName --policy-name LocationRole --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured deleting a policy\n"
#fi
#printf "Removed policy from user\n"
#
#aws iam remove-user-from-group --group-name $groupName --user-name $userName --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured removing the user from a group\n"
#fi
#printf "Removed user from group\n"
#
#aws iam delete-group --group-name $groupName --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured deleting the group\n"
#fi
#printf "Deleted group\n"
#
#aws iam delete-login-profile --user-name $userName --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured removing the users login permissions (profile) \n"
#fi
#printf "Removed user login permissions\n"
#
#aws iam delete-user --user-name $userName --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured deleting the user\n"
#fi
#printf "Deleted user\n"
