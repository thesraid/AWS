#!/bin/bash

i=101

while [ $i -le 114 ]
do
   aws configure set region us-east-1 --profile AVStudent$i
   ami=($(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output=text --profile AVStudent$i))
   echo "AVStudent$i : $ami"
   aws ec2 modify-instance-attribute --no-disable-api-termination --instance-id $ami --profile AVStudent$i
   i=$[$i+1]
done

#for i in $( eval echo {$first..20} )
#do
#   echo $i
#done
