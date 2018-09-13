#!/bin/bash

# joriordan

# Prints out the usage of the scipt
function usage
{
    echo "usage: finish_Course.sh [-h]
				      --account_name [-a] ACCOUNT_NAME"
}


# Create a variable to store the account name
accName=""

# Reads the input switches and assigns the Account Name to the accName 
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

# If an accName was not proivded when the script was run prompt the user to enter one. 
if [ "$accName" = "" ]
then
  # List out the accounts so that the user can copy and paste to make it easier
  aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[*].Name' 
  printf "Please enter the name of the account (with or without quotes) : "
  read accName
  # Remove quotes if entered
  accName=$(sed -e 's/^"//' -e 's/"$//' <<< $accName)
  printf "You chose $accName \n"
fi

# Find the accountID for the entered account.
accID=$(aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[?Name==`'$accName'`].Id' --output text)
if [ "$accID" = "" ] 
then
   printf "Invalid account\n"
   exit
fi
printf "The account ID for $accName is $accID\n"

# The profile is what aws cli uses to identify the account. For simplicity we will set this to the account name
# We will also greate a user and group with the same name
profile=$accName
userName=$accName
groupName=$accName

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

# Iterate through each AWS region and remove any labs 
ARRAY=($(aws ec2 describe-regions --query Regions[*].RegionName --output text --profile cliaccount))
for region in "${ARRAY[@]}"
do

   printf "."

   # Tell the aws cli to use a region. The region is whichever region we are currently on in the array above. 
   aws configure set region $region --profile $profile
   if [ $? -ne 0 ]
   then
     printf "Error occured connecting to the account\n"
     exit 1
   fi

   # Get a list of instances running in this region and terminate them.   
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
   
      # Give instances time to shut down - This should really be iplemented to wait until all instances show as terminated but it seems to work fine this way
      sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "."
      sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "."
      sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf "." && sleep 10 && printf ".\n"
   fi

   # Linux SSH keys will be deleted
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

   
   # Get a list of stacks in the region and delete them. Deleting a stack will deelte all resources created by the stack, Networks, GWs, SecGrps etc. 
   STACKS=($(aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile $profile))

   #printf "Found the following stacks : \n"
   #for STACK in "${STACKS[@]}"
   #do
   #   echo $STACK
   #done
   
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
      
      # In the loop above we run the desribe stack command to and pull out the current state. Once the Stack is deleted we will get the error below as it no longer exists. 
      # There is no way to supporess this message unless we supress all output from he stack deletion which would be bad if something else when wrong
      printf "An error occurred (ValidationError) when calling the DescribeStacks operation: Stack with id $STACK does not exist << IGNORE THIS ERROR IF SEEN ABOVE\n"
      printf "\n$STACK deleted in $region\n"


      # Cloudtrail will be deleted here as we know the region with the Stack is also the region with the trail
      TRAILS=($(aws cloudtrail describe-trails --query trailList[*].Name --output text --profile $profile))
      for trail in "${TRAILS[@]}"
      do
         printf "\nDeleting the CloudTrail $trail\n"
         aws cloudtrail delete-trail --name $trail --output text --profile $profile 
         if [ $? -ne 0 ]
         then
            printf "Error occured removing the CloudTrail $trail\n"
            exit 1
         fi
      done

      # VPC flows will be deleted here as we know the region with the Stack is also the region with the flow
      FLOWS=($(aws ec2 describe-flow-logs --query FlowLogs[*].FlowLogId --output text  --profile $profile))
      for flow  in "${FLOWS[@]}"
      do
         printf "\nDeleting VPC Flow called $flow\n"
         aws ec2 delete-flow-logs --flow-log-ids $flow  --profile $profile > /dev/null
         if [ $? -ne 0 ]
         then
            printf "Error occured removing the VPC Flow $flow\n"
            exit 1
         fi
      done
   
      # Delete log groups
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

      BUCKETS=($(aws s3 ls --profile $profile | awk '{print $3}'))
   
      for bucket in "${BUCKETS[@]}"
      do
         printf "\nDeleting the Bucket $bucket and its contents\n"
         aws s3 rm s3://$bucket --recursive --profile $profile > /dev/null
         aws s3api delete-bucket --bucket $bucket --profile $profile
         if [ $? -ne 0 ]
         then
            printf "Error occured removing the Bucket $bucket\n"
            exit 1
         fi
      done

      # Here we delete all Security Groups except for the default one as it can't be deleted and would cause an error
      SECGROUPS=($(aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text --profile $profile))
   
      for secgroup in "${SECGROUPS[@]}"
      do
         if [ $secgroup != "default" ]
         then
            printf "\nDeleting the Security Group $secgroup\n"
            aws ec2 delete-security-group --group-id $secgroup --output text --profile $profile
            if [ $? -ne 0 ]
            then
               printf "Error occured removing the Security Group $secgroup\n"
               exit 1
            fi
         fi
      done
   done
   
   # Here we delete all roles except for the built in ones which can't be deleted and would cause an error
   # When delting a role you also have to detach/delete any policies or profiles it has 
   ROLES=($(aws iam list-roles --query Roles[*].RoleName --profile $profile --output text))
   
   string=""
   for role in "${ROLES[@]}"
   do
      if [ "$role" != "AWSServiceRoleForOrganizations" ] && [ "$role" != "OrganizationAccountAccessRole" ] && [[ "$role" != Sensor-ReadOnlyRoleWithCloudTrailManagement* ]] && [ "$role" != "AWSServiceRoleForSupport" ] && [[ "$role" != "AWSServiceRoleForTrustedAdvisor" ]]
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

# Premissions are added to the group that the user is attached to rather than the user themselves. This is becuase you can add a greater amount of permissions to a group
#printf "\nRemoving the specified user account\n"
#
#aws iam delete-group-policy --group-name $groupName --policy-name StudentRole --profile $profile
#aws iam delete-group-policy --group-name $groupName --policy-name LocationRole --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured deleting a policy\n"
#  exit 1
#fi
#printf "Removed policy from user\n"
#
#aws iam remove-user-from-group --group-name $groupName --user-name $userName --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured removing the user from a group\n"
#  exit 1
#fi
#printf "Removed user from group\n"
#
#aws iam delete-group --group-name $groupName --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured deleting the group\n"
#  exit 1
#fi
#printf "Deleted group\n"
#
#aws iam delete-login-profile --user-name $userName --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured removing the users login permissions (profile) \n"
#  exit 1
#fi
#printf "Removed user $userName login permissions\n"
#
#aws iam delete-user --user-name $userName --profile $profile
#if [ $? -ne 0 ]
#then
#  printf "Error occured deleting the user\n"
#  exit 1
#fi
#printf "Deleted user $userName\n"
printf "\n"
