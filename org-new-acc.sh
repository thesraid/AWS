#!/bin/bash
function usage
{
    echo "usage: organization_new_acc.sh [-h] 
				      --account_name [-n] ACCOUNT_NAME
                                      --account_email [-e] ACCOUNT_EMAIL
                                      --cl_profile_name [-c] CLI_PROFILE_NAME
				      --user_name [-u] USER_NAME
                        	      --password [-p] PASSWORD
                        	      --group_name [-g] GROUP_NAME
                        	      --policy [-y] POLICY
                                      [--region [-r] AWS_REGION]"
}

newAccName=""
newAccEmail=""
newProfile=""
roleName="OrganizationAccountAccessRole"
destinationOUname="Students"
region="eu-west-1"

while [ "$1" != "" ]; do
    case $1 in
        -n | --account_name )   shift
                                newAccName=$1
                                ;;
        -e | --account_email )  shift
                                newAccEmail=$1
                                ;;
        -c | --cl_profile_name ) shift
                                newProfile=$1
                                ;;
        -r | --region )        shift
                                region=$1
                                ;;
        -u | --user_name )      shift
                                userName=$1
                                ;;
        -p | --password)        shift
                                userPassword=$1
                                ;;
        -g | --group_name )     shift
                                groupName=$1
                                ;;
        -y | --policy )         shift
                                policy=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$newAccName" = "" ] || [ "$newAccEmail" = "" ] || [ "$newProfile" = "" ] || [ "$destinationOUname" = "" ] || [ "$region" = "" ] || [ "$userName" = "" ] || [ "$userPassword" = "" ] || [ "$groupName" = "" ] || [ "$policy" = "" ]
then
  usage
  exit
fi

printf "Create New Account\n"
ReqID=$(aws organizations create-account --email $newAccEmail --account-name "$newAccName" --role-name $roleName \
--query 'CreateAccountStatus.[Id]' \
--output text)

printf "Waiting for New Account ..."
orgStat=$(aws organizations describe-create-account-status --create-account-request-id $ReqID \
--query 'CreateAccountStatus.[State]' \
--output text)

while [ $orgStat != "SUCCEEDED" ]
do
  if [ $orgStat = "FAILED" ]
  then
    printf "\nAccount Failed to Create\n"
    exit 1
  fi
  printf "."
  sleep 10
  orgStat=$(aws organizations describe-create-account-status --create-account-request-id $ReqID \
  --query 'CreateAccountStatus.[State]' \
  --output text)
done

accID=$(aws organizations describe-create-account-status --create-account-request-id $ReqID \
--query 'CreateAccountStatus.[AccountId]' \
--output text)

accARN="arn:aws:iam::$accID:role/$roleName"

printf "\nCreate New CLI Profile\n"
aws configure set region $region --profile $newProfile
aws configure set role_arn $accARN --profile $newProfile
aws configure set source_profile default --profile $newProfile

cfcntr=0
printf "Waiting for CF Service ..."
aws cloudformation list-stacks --profile $newProfile > /dev/null 2>&1
actOut=$?
while [[ $actOut -ne 0 && $cfcntr -le 10 ]]
do
  sleep 5
  aws cloudformation list-stacks --profile $newProfile > /dev/null 2>&1
  actOut=$?
  if [ $actOut -eq 0 ]
  then
    break
  fi
  printf "."
  cfcntr=$[$cfcntr +1]
done

if [ $cfcntr -gt 10 ]
then
  printf "\nCF Service not available\n"
  exit 1
fi

printf "\nCreate VPC Under New Account\n"
aws cloudformation create-stack --stack-name VPC --template-url https://s3-eu-west-1.amazonaws.com/deploy-student-env/ANYSA_VPC.json --parameters ParameterKey=JEOSName,ParameterValue=JEOS ParameterKey=WinVictName,ParameterValue=WinVict ParameterKey=PTName,ParameterValue=PTest ParameterKey=WinJumpboxName,ParameterValue=JumpBox --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "CF VPC Stack Failed to Create\n"
  exit 1
fi

printf "Waiting for CF Stack to Finish ..."
cfStat=$(aws cloudformation describe-stacks --stack-name VPC --profile $newProfile --query 'Stacks[0].[StackStatus]' --output text)
while [ $cfStat != "CREATE_COMPLETE" ]
do
  sleep 5
  printf "."
  cfStat=$(aws cloudformation describe-stacks --stack-name VPC --profile $newProfile --query 'Stacks[0].[StackStatus]' --output text)
  if [ $cfStat = "CREATE_FAILED" ]
  then
    printf "\nVPC Failed to Create\n"
    exit 1
  fi
done
printf "\nVPC Created\n"

printf "Creating User Login Profile\n"
printf "Creating a new user\n"
aws iam create-user --user-name $userName --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured creating a user\n"
  exit 1
fi

printf "Creating a new group\n"
aws iam create-group --group-name $groupName --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured creating a group\n"
  exit 1
fi

printf "Adding the user to the group\n"
aws iam add-user-to-group --user-name $userName --group-name $groupName --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured adding the user to the group\n"
  exit 1
fi

printf "Making the user a poweruser\n"
aws iam put-user-policy --user-name $userName --policy-name StudentPowerUserRole --policy-document $policy --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured assigning the policy to the user\n"
  exit 1
fi

printf "Giving user a login password\n"
aws iam create-login-profile --user-name $userName --password $userPassword --profile $newProfile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured setting the users login and password\n"
  exit 1
fi

printf "Created User\n"

printf "Adding to Parent Org\n"
if [ "$destinationOUname" != "" ]
then
  printf "Moving New Account to OU\n"
  rootOU=$(aws organizations list-roots --query 'Roots[0].[Id]' --output text)
  destOU=$(aws organizations list-organizational-units-for-parent --parent-id $rootOU --query 'OrganizationalUnits[?Name==`'$destinationOUname'`].[Id]' --output text)

  aws organizations move-account --account-id $accID --source-parent-id $rootOU --destination-parent-id $destOU 
  if [ $? -ne 0 ]
  then
    printf "Moving Account Failed\n"
  fi
fi

echo New Account ID is $accID

