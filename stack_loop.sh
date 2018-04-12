#!/bin/bash
ARRAY=($(aws cloudformation describe-stacks --query Stacks[*].StackName --output text --profile cliaccount)) 

for i in "${ARRAY[@]}"
do
echo $i
done
