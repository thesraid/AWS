#!/bin/bash

i=10

while [ $i -le 200 ]
do
   aws configure set region us-east-1 --profile AVStudent$i
   printf AVStudent$i
   aws ec2 describe-volumes --output=text --profile AVStudent$i
   printf "\n"
   i=$[$i+1]
done

#for i in $( eval echo {$first..20} )
#do
#   echo $i
#done
