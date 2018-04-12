#!/bin/bash

for accounts in {01..07}
do
   s="AVStudent$accounts"
   p="Profile"
   profile=$s$p
   echo $profile
   echo "Stacks : "
   aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile $profile
   echo "Instances : "
   aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value,State.Name]' --output text --profile $profile
   printf "\n"
done

printf "cliaccount\n"
echo "Stacks : "
aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile cliaccount
echo "Instances : "
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value,State.Name]' --output text --profile cliaccount
printf "\n"
