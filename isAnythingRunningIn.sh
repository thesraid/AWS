#!/bin/bash
function usage
{
    echo "usage: isAnythingRunning.sh [-h]
                                      --region [-r] If not specified all regions will be checked"
}

while [ "$1" != "" ]; do
    case $1 in
        -r | --region )         shift
                                ARRAY=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done


if [ -z "$ARRAY" ]
then
   ARRAY=($(aws ec2 describe-regions --query Regions[*].RegionName --output text --profile cliaccount))
fi

printf "cliaccount\n"
users=($(aws iam list-users --output text --query 'Users[*].UserName' --profile cliaccount))
if [ ! -z "$users" ]
then
   printf "Users : "
   aws iam list-users --output text --query 'Users[*].UserName' --profile cliaccount | tr -d "\n"
   printf "\n"
fi

#ARRAY=($(aws ec2 describe-regions --query Regions[*].RegionName --output text --profile cliaccount))
for region in "${ARRAY[@]}"
do
   aws configure set region $region --profile cliaccount
   stacks=($(aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile cliaccount))
   if [ ! -z "$stacks" ]
   then
      printf "\ncliaccount $region Stacks : "
      for stack in "${stacks[*]}"
      do
         printf "$stack"
      done
   fi
   instances=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value]' --output text --profile cliaccount))
   #instances=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value,State.Name]' --output text --profile cliaccount))
   if [ ! -z "$instances" ]
   then
      printf "\ncliaccount $region Instances : "
      for instance in "${instances[*]}"
      do
         printf "$instance"
      done
      printf "\n"
   fi
   printf "."
done

printf "\n\n"

count=$(aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --output text --query 'Accounts[*].[Name,Id]' | wc -l)
#echo $count
((count = count - 1))
NumberOfAccounts=($(seq -f '%02g' 1 $count))



for accounts in "${NumberOfAccounts[@]}"
#for ((accounts=01;accounts<=count;accounts++))
#for accounts in $(seq 01 $count)
do
   profile="AVStudent$accounts"
   echo $profile
   users=($(aws iam list-users --output text --query 'Users[*].UserName' --profile $profile))
   if [ ! -z "$users" ]
   then
      printf "Users : "
      aws iam list-users --output text --query 'Users[*].UserName' --profile $profile | tr -d "\n"
      printf "\n"
   fi
   
   #ARRAY=($(aws ec2 describe-regions --query Regions[*].RegionName --output text --profile $profile))
   for region in "${ARRAY[@]}"
   do
      aws configure set region $region --profile $profile
      stacks=($(aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile $profile))
      if [ ! -z "$stacks" ]
      then
         printf "\n$profile $region Stacks : "
         for stack in "${stacks[*]}"
         do
            printf "$stack"
         done
      fi
      instances=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value]' --output text --profile $profile))
      #instances=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value,State.Name]' --output text --profile $profile))
      if [ ! -z "$instances" ]
      then
         printf "\n$profile $region Instances : "
         for instance in "${instances[*]}"
         do
            printf "$instance"
         done
         printf "\n"
      fi
      printf "."
   done
printf "\n\n"
done

