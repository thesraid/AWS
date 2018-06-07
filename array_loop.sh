#!/bin/bash
ARRAY=($(aws ec2 describe-regions --query Regions[*].RegionName --output text --profile cliaccount)) 
for region in "${ARRAY[@]}"
do
	echo $region
done



#ARRAY=($(aws iam list-roles --query Roles[*].RoleName --profile cliaccount --output text)) 
#
#string=""
#for role in "${ARRAY[@]}"
#do
#   if [ "$role" != "AWSServiceRoleForOrganizations" ] && [ "$role" != "OrganizationAccountAccessRole" ]
#   then
#     PROFILES=($(aws iam list-instance-profiles-for-role --role-name $role --query InstanceProfiles[*].InstanceProfileName --output text --profile cliaccount))
#     for profile in "${PROFILES[@]}"
#     do
#        aws iam remove-role-from-instance-profile --instance-profile-name $profile --role-name $role --profile cliaccount
#     done
#     POLICIES=($(aws iam list-attached-role-policies --query AttachedPolicies[*].PolicyArn --role-name $role --output text --profile cliaccount))
#     for policy in "${POLICIES[@]}"
#     do
#        aws iam detach-role-policy --role-name $role --policy-arn $policy --profile cliaccount
#     done
#     aws iam delete-role --role-name $role --profile cliaccount
#     echo " "
#   fi
#done


