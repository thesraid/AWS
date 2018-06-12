#!/bin/bash
function usage
{
    echo "usage: finish_Course.sh [-h]
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

profile=$accName
userName=$accName
groupName=$accName

ARRAY=($(aws ec2 describe-regions --query Regions[*].RegionName --output text --profile cliaccount))
for region in "${ARRAY[@]}"
do

   printf "."

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
      printf "\nTerminating Instances in $region"
      aws ec2 terminate-instances --instance-ids $INSTANCES_STRING --profile $profile
      if [ $? -ne 0 ]
      then
        printf "FAILED to terminate all Instancese in $region\n"
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
   
      printf "\nDeleting $STACK in $region \n"
      aws cloudformation delete-stack --stack-name $STACK --profile $profile
      if [ $? -ne 0 ]
      then
        printf "$STACK FAILED to Delete in $region\n"
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
          printf "\n$STACK FAILED to delete in $region\n"
          printf "MANUAL CLEANUP REQUIRED\n"
          exit 1
        fi
      done
      printf "An error occurred (ValidationError) when calling the DescribeStacks operation: Stack with id $STACK does not exist << IGNORE THIS ERROR IF SEEN ABOVE\n"
      printf "\n$STACK deleted in $region\n"
   done
   
   KEYS=($(aws ec2 describe-key-pairs --query KeyPairs[*].KeyName --output text --profile $profile))
   
   for KEY in "${KEYS[@]}"
   do
        printf "\nDeleting Keys in $region\n"
   	aws ec2 delete-key-pair --key-name $KEY --profile $profile
   	if [ $? -ne 0 ]
      	then
           printf "$KEY FAILED to Delete in $region\n"
      	fi
   done

   FLOWS=($(aws ec2 describe-flow-logs --query FlowLogs[*].FlowLogId --output text  --profile $profile))

   for flow  in "${FLOWS[@]}"
   do
      printf "\nDeleting VPC Flow called $flow\n"
      aws ec2 delete-flow-logs --flow-log-ids $flow  --profile $profile > /dev/null 2>&1
   done

   LOGGROUPS=($(aws logs describe-log-groups --query logGroups[*].logGroupName --output text --profile $profile))
  
   for group in "${LOGGROUPS[@]}"
   do
      printf "\nDeleting Log Group called called $group\n"
      aws logs delete-log-group --log-group-name $group --output text --profile $profile
      if [ $? -ne 0 ]
      then
         printf "Error occured removing the Log Group $group\n"
         exit 1
      fi
   done

   
   ROLES=($(aws iam list-roles --query Roles[*].RoleName --profile $profile --output text))
   
   string=""
   for role in "${ROLES[@]}"
   do
      if [ "$role" != "AWSServiceRoleForOrganizations" ] && [ "$role" != "OrganizationAccountAccessRole" ] && [[ "$role" != Sensor-ReadOnlyRoleWithCloudTrailManagement* ]]
      then
        printf "\nDeleting Role called $role\n"
        PROFS=($(aws iam list-instance-profiles-for-role --role-name $role --query InstanceProfiles[*].InstanceProfileName --output text --profile $profile))
        for prof in "${PROFS[@]}"
        do
           aws iam remove-role-from-instance-profile --instance-profile-name $prof --role-name $role --profile $profile
           aws iam delete-instance-profile --instance-profile-name $prof --profile $profile
        done
        ATTACHEDPOLICIES=($(aws iam list-attached-role-policies --query AttachedPolicies[*].PolicyArn --role-name $role --output text --profile $profile))
        for policy in "${ATTACHEDPOLICIES[@]}"
        do
           aws iam detach-role-policy --role-name $role --policy-arn $policy --profile $profile
        done
        ROLEPOLICIES=($(aws iam list-role-policies --role-name $role --query PolicyNames[*] --output text --profile $profile))
	for policy in "${ROLEPOLICIES[@]}"
        do
            aws iam delete-role-policy --role-name $role --policy-name $policy --profile $profile
        done
        aws iam delete-role --role-name $role --profile $profile
        echo " "
      fi
   done
done

printf "\nRemoving the specified user account\n"

aws iam delete-group-policy --group-name $groupName --policy-name StudentRole --profile $profile
aws iam delete-group-policy --group-name $groupName --policy-name LocationRole --profile $profile
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

