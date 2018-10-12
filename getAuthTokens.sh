#!/bin/bash

connect () {

accountName=$1
accountID=$2

echo "$accountName has the ID $accountID"
role="OrganizationAccountAccessRole"
aws sts assume-role --role-arn arn:aws:iam::$accountID:role/$role --role-session-name $accountName
aws configure set region eu-west-1 --profile $accountName
aws configure set role_arn arn:aws:iam::$accountID:role/$role --profile $accountName
aws configure set source_profile default --profile $accountName
}


accArray=($(aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --output text --query 'Accounts[*].[Name,Id]' | sort -V))
arraySize=${#accArray[@]}

i=0
while [ $i -lt $arraySize ]
do
   j=$[$i+1]
   connect ${accArray[$i]} ${accArray[$j]}
   i=$[$i+2]
done

