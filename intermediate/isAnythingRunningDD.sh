#!/bin/bash
function usage
{
    echo "usage: isAnythingRunning.sh [-h]
                                      --region [-r] If not specified all regions will be checked
                                      --start [-s] 10	AVStudent account to start with
                                      --end [-e] 20     AVStudent account to end on
                                                        If start or end are not specified it will run to the end
"
}

while [ "$1" != "" ]; do
    case $1 in
        -r | --region )         shift
                                REGIONS=$1
                                ;;
        -s | --start )          shift
                                begin=$1
                                ;;
        -e | --end )            shift
                                end=$1
                                ;;
        -c | --cli )            shift
                                cli=true
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done


if [ -z "$REGIONS" ]
then
   REGIONS=($(aws ec2 describe-regions --query Regions[*].RegionName --output text --profile cliaccount))
fi


if [ "$cli" = true ];
then

   printf "dustin\n"
   users=($(aws iam list-users --output text --query 'Users[*].UserName' --profile dustin))
   if [ ! -z "$users" ]
   then
      printf "Users : "
      aws iam list-users --output text --query 'Users[*].UserName' --profile dustin | tr -d "\n"
      printf "\n"
   fi

   #ARRAY=($(aws ec2 describe-regions --query Regions[*].RegionName --output text --profile cliaccount))
   for region in "${REGIONS[@]}"
   do
      aws configure set region $region --profile dustin
      stacks=($(aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile dustin))
      if [ ! -z "$stacks" ]
      then
         printf "\ndustin $region Stacks : "
         for stack in "${stacks[*]}"
         do
            printf "$stack"
         done
      fi
      instances=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value]' --output text --profile dustin))
      #instances=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value,State.Name]' --output text --profile cliaccount))
      if [ ! -z "$instances" ]
      then
         printf "\ndustin $region Instances : "
         for instance in "${instances[*]}"
         do
            printf "$instance"
         done
         printf "\n"
      fi
      printf "."
   done

   printf "\n\n"


fi

NumberOfAccounts=()

if [ -z "$begin" ] || [ -z "$end" ]
then
   count=$(aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --output text --query 'Accounts[*].[Name,Id]' | wc -l)
   #echo $count
   ((count = count - 1))
   NumberOfAccounts=($(seq -f '%02g' 1 $count))
else
   end=$[$end+1]
   while [ $begin -lt $end ]
   do
      NumberOfAccounts+=($begin)
      begin=$[$begin+1]
   done

fi


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
   for region in "${REGIONS[@]}"
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

