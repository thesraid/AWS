#!/bin/bash

profile="AVStudent201"
USMBaseSG=""
INSTANCES=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text --profile $profile))
SECGROUPS=($(aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupName]' --output text --profile $profile))

for secGroup in "${SECGROUPS[@]}"
do
	if [[ $secGroup == "Sensor-USMBaseSG"* ]]; then
		USMBaseSG=$(aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName==`'$secGroup'`].[GroupId]' --output text --profile $profile)
	fi
done

for instance in "${INSTANCES[@]}"
do
	aws ec2 modify-instance-attribute --instance-id $instance --groups $USMBaseSG --profile $profile
done

aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,SecurityGroups]' --output text --profile $profile
