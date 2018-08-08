#!/bin/bash
SECGROUPS=($(aws ec2 describe-security-groups --query SecurityGroups[*].GroupName --output text --profile AVStudent02))

   for secgroup in "${SECGROUPS[@]}"
   do
      if [ $secgroup != "default" ]
      then
         printf "\nDeleting the Security Group $secgroup\n"
         aws ec2 delete-security-group --group-name $secgroup --output text --profile AVStudent02 
         if [ $? -ne 0 ]
         then
            printf "Error occured removing the Security Group $secgroup\n"
            exit 1
         fi
      fi
   done

