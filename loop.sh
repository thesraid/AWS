#!/bin/bash

i=10

while [ $i -lt 101 ]
do
   echo "aws iam create-account-alias --account-alias avstudent$i --profile AVStudent$i"
   aws iam create-account-alias --account-alias avstudent$i --profile AVStudent$i
   i=$[$i+1]
done
