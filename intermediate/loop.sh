#!/bin/bash

first=01

#while [ $i -lt 10 ]
#do
   #echo "aws iam create-account-alias --account-alias avstudent$i --profile AVStudent$i"
   #aws iam create-account-alias --account-alias avstudent$i --profile AVStudent$i
   #printf "Creating AVAdmin for AVStudent$i\n"
   #labCreateAdmin -p Password1! -a AVStudent$i 
   #labRemoveAdmin -a AVStudent$i 
   #aws iam list-account-aliases --output text --profile AVStudent$i
   #labFinish -a AVStudent$i
   #echo $i
   #i=$[$i+1]
#done

for i in $( eval echo {$first..20} )
do
   echo $i
done
