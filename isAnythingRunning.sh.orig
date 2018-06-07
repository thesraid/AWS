#!/bin/bash

printf "cliaccount\n"
printf "Users : "
aws iam list-users --output text --query 'Users[*].UserName' --profile cliaccount | tr -d "\n"
printf "\n"
aws configure set region eu-west-1 --profile cliaccount
printf "EU Stacks : "
aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile cliaccount
printf "\n"
printf "EU Instances : "
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value,State.Name]' --output text --profile cliaccount
printf "\n"
aws configure set region us-east-1 --profile cliaccount
printf "US Stacks : "
aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile cliaccount
printf "\n"
printf "US Instances : "
printf "\n\n"

count=$(aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --output text --query 'Accounts[*].[Name,Id]' | wc -l)
echo $count

for accounts in {01..18}
#for ((accounts=01;accounts<=count;accounts++))
#for accounts in $(seq 01 $count)
do
   s="AVStudent$accounts"
   p="Profile"
   profile=$s$p
   echo $profile
   printf "Users : "
   aws iam list-users --query 'Users[*].UserName' --output text --profile $profile | tr -d "\n"
   printf "\n"
   aws configure set region eu-west-1 --profile $profile
   printf "EU Stacks : "
   aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile $profile 
   printf "\n"
   printf "EU Instances : "
   aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value,State.Name]' --output text --profile $profile 
   printf "\n"
   aws configure set region us-east-1 --profile $profile
   printf "US Stacks : "
   aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile $profile 
   printf "\n"
   printf "US Instances : "
   aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value,State.Name]' --output text --profile $profile 
   printf "\n\n"
done

