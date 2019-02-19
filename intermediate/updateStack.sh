#!/bin/bash

# Update the cloudFormation template of running labs

# The start and end AVStudent accounts to apply the changes to
i=101
j=112

# The new cloudFormation template that should be applied
url="https://s3-eu-west-1.amazonaws.com/deploy-student-env/ANYDC.json"

while [ $i -le $j ]
do

   # Set the region
   profile=AVStudent$i
   aws configure set region us-east-1 --profile $profile
   printf "$profile \n"

   # THere will be a few stacks. Find the main ANYDC-v3 one
   stackName=$(aws cloudformation describe-stacks --profile $profile --query 'Stacks[?Description==`Deploy ANYDC-v3`].StackName' --output text)
   if [ -z "$stackName" ]; then
      printf "No ANYDC stack found for $profile. Skipping...\n"
   else
      printf "Updating $stackName\n"

      # Apply the new json file and capture the changeSet ID
      changeSetID=$(aws cloudformation create-change-set --stack-name $stackName --change-set-name ANYDC-permUpdate-Changed --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey="TrainingVPC",UsePreviousValue=true ParameterKey="userPassword",UsePreviousValue=true ParameterKey="account",UsePreviousValue=true --template-url $url --query 'Id' --output text --profile $profile)

      # Wait for the changes to propogate
      sleep 10

      # Apply the changes
      aws cloudformation execute-change-set --change-set-name $changeSetID --profile $profile

      cfStat="intial"
      # Loop until the stack status is UPDATE_COMPLETE. If we get an error status then error out
      printf "Waiting for $stackName stack to update ..."
      cfStat=$(aws cloudformation describe-stacks --stack-name $stackName --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
      while [ "$cfStat" != "UPDATE_COMPLETE" ]
      do
        sleep 5
        printf "."
        cfStat=$(aws cloudformation describe-stacks --stack-name $stackName --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
        if [ "$cfStat" = "UPDATE_FAILED" ] || [ "$cfStat" = "ROLLBACK_COMPLETE" ]
        then
          printf "\n$stackName Stack failed to update\n" | tee error-$profile-$stackName.txt /var/log/labs/error/error-$profile-$stackName.log
          printf "ERROR : $cfStat\n" | tee error-$profile-$stackName.txt /var/log/labs/error/error-$profile-$stackName.log
          aws cloudformation describe-stacks --stack-name $stackName --profile $profile | tee error-$profile-$stackName.txt /var/log/labs/error/error-$profile-$stackName.log
          aws cloudformation describe-stack-events --no-paginate --stack-name $stackName --profile $profile | tee error-$profile-$stackName.txt /var/log/labs/error/error-$profile-$stackName.log
          printf "\n\n*** View error-$profile-$stackName.log for more detailed error information ***\n"
          printf "*** *** ***            Error file is read from the bottom up       *** *** ***\n"
          exit 1
        fi
      done
      printf "\n$stackName updated\n"
   fi

   printf "\n"
   i=$[$i+1]
done

#for i in $( eval echo {$first..20} )
#do
#   echo $i
#done
