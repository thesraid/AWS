#!/bin/bash
ARRAY=(AVStudent16 AVStudent17 AVStudent18 AVStudent19 AVStudent20 AVStudent21 AVStudent22 AVStudent23 AVStudent24 AVStudent25) 
for student in "${ARRAY[@]}"
do
	echo $student
        ./start_Course.sh -a $student -p Password1! -r us-east-1 -c ANYDC -s no
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


