#!/bin/bash

i=81

while [ $i -lt 101 ]
do
   echo "./org-new-acc.sh -n AVStudent$i -e avstudent$i@alien-training.com | tee newOrgs.txt"
   ./org-new-acc.sh -n AVStudent$i -e avstudent$i@alien-training.com | tee -a newOrgs.txt
   i=$[$i+1]
   echo " "
   echo "*****************************************"
   echo " "
done
