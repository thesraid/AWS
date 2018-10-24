#!/bin/bash
for accounts in {01..18}
do
   s="AVStudent$accounts"
   p="Profile"
   profile=$s$p
   echo $profile
   #./new_user.sh -u $s -p 'Password1!' -g $s -o file://AdminPolicy.json -c $profile
   ./delete_user.sh -u $s -g $s -c $profile
   printf "\n"
done

