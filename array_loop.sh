#!/bin/bash
ARRAY=($(aws ec2 describe-instance-status --query InstanceStatuses[*].InstanceId --output text --profile cliaccount)) 

string=""
for i in "${ARRAY[@]}"
do
 string+=" $i"
done

echo $string

aws ec2 terminate-instances --instance-ids $string --dry-run --profile cliaccount
