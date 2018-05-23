#!/bin/bash
function usage
{
    echo "usage: start_Course.sh [-h] 
				      --account_name [-a] ACCOUNT_NAME
				      --password [-p] PASSWORD
				      --region [r] REGION
				      --course [-c] COURSE"
}

accName=""
role="OrganizationAccountAccessRole"
destinationOUname="Students"
region=""
course=""
url=""

while [ "$1" != "" ]; do
    case $1 in
        -a | --account_name )   shift
                                accName=$1
                                ;;
	-p | --password)	shift
				userPassword=$1
				;;
        -r | --region )         shift
                                region=$1
                                ;;
        -c | --course )         shift
                                course=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$accName" = "" ]
then
  aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[*].Name' 
  printf "Please enter the name of the account (with or without quotes) : "
  read accName
  # Remove quotes if entered
  accName=$(sed -e 's/^"//' -e 's/"$//' <<< $accName)
  printf "You chose $accName \n"
fi

accID=$(aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[?Name==`'$accName'`].Id' --output text)
if [ "$accID" = "" ] 
then
   printf "Invalid account\n"
   exit
fi
printf "The account ID for $accName is $accID\n"

profile=$accName"Profile"
printf "Profile name is now $profile\n"

if [ "$userPassword" = "" ]
then
   printf "\nEnter desired user password : "
   read userPassword
   printf "\n"
fi


if [ "$region" = "" ]
then
   printf "\nAvailable Regions\n"
   printf "   eu-west-1\n"
   printf "   us-east-1\n"
   printf "\n"
   printf "Please choose a region : "
   read region
   region=$(sed -e 's/^"//' -e 's/"$//' <<< $region)
   printf "You chose $region\n"
fi

if [ "$region" != "eu-west-1" ] && [ "$region" != "us-east-1" ]
then
   printf "Invalid region\n"
   exit
fi

expiry=$(aws sts assume-role --role-arn arn:aws:iam::$accID:role/$role --query 'Credentials.Expiration' --role-session-name $profile)
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi

printf "Connection valid to $accName until $expiry\n"

aws configure set region $region --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi

aws configure set role_arn arn:aws:iam::$accID:role/$role --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi

aws configure set source_profile default --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi


if [ "$course" = "" ]
then
   printf "\nAvailable courses\n"
   printf "   ANYDC\n"
   printf "   ANYSA\n"
   printf "\nChoose the course : "
   read course
   printf "You chose $course\n"
fi

if [ "$course" != "ANYDC" ] && [ "$course" != "ANYSA" ]
then
   printf "Invalid course\n"
   exit
fi

if [ "$course" = "ANYDC" ]
then
  url="https://s3-eu-west-1.amazonaws.com/deploy-student-env/ANYDC_new.json"
fi

if [ "$course" = "ANYSA" ]
then
  url="https://s3-eu-west-1.amazonaws.com/deploy-student-env/ANYSA.json"
fi



cfcntr=0
printf "Waiting for CloudFormation Service ..."
aws cloudformation list-stacks --profile $profile > /dev/null 2>&1
actOut=$?
while [[ $actOut -ne 0 && $cfcntr -le 10 ]]
do
  sleep 5
  aws cloudformation list-stacks --profile $profile > /dev/null 2>&1
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
  printf "\nCloudFormation Service not available\n"
  exit 1
fi

printf "\nCreating Student Lab Under New Account\n"
vpcid=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[*].VpcId --output=text --profile $profile)
aws cloudformation create-stack --stack-name $course --template-url $url --parameters ParameterKey=TrainingVPC,ParameterValue=$vpcid --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Student Lab Failed to Create\n"
  exit 1
fi

printf "Waiting for Student Lab to start ..."
cfStat=$(aws cloudformation describe-stacks --stack-name $course --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
while [ $cfStat != "CREATE_COMPLETE" ]
do
  sleep 5
  printf "."
  cfStat=$(aws cloudformation describe-stacks --stack-name $course --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
  if [ $cfStat = "CREATE_FAILED" ] || [ $cfStat = "ROLLBACK_COMPLETE"  ]
  then
    printf "\nStudent Lab failed to start\n"
    printf "ERROR : $cfStat\n"
    aws cloudformation describe-stacks --stack-name $course --profile $profile
    exit 1
  fi
done
printf "\nStudent Lab started\n"

userName=$accName
groupName=$accName
#policy="file://DBPolicy.json"
policy="file://StudentPolicy.json"

printf "Creating a new user\n"
aws iam create-user --user-name $userName --profile $profile 
if [ $? -ne 0 ]
then
  printf "Error occured creating a user\n"
  exit 1
fi

printf "Creating a new group\n"
aws iam create-group --group-name $groupName --profile $profile > /dev/null 
if [ $? -ne 0 ]
then
  printf "Error occured creating a group\n"
  exit 1
fi

printf "Adding the user to the group\n"
aws iam add-user-to-group --user-name $userName --group-name $groupName --profile $profile 
if [ $? -ne 0 ]
then
  printf "Error occured adding the user to the group\n"
  exit 1
fi

printf "Assigning a policy\n"
aws iam put-user-policy --user-name $userName --policy-name StudentRole --policy-document $policy --profile $profile 
if [ $? -ne 0 ]
then
  printf "Error occured assigning the policy to the user\n"
  exit 1
fi

printf "Giving user a login password\n"
aws iam create-login-profile --user-name $userName --password $userPassword --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured setting the users login and password\n"
  exit 1
fi

printf "Students can now log into\n"
printf "URL  : https://$region.signin.aws.amazon.com\n"
printf "ACC  : $accID\n"
printf "USER : $userName\n"
printf "PASS : $userPassword\n"
aws cloudformation describe-stacks --stack-name $course --profile $profile --query 'Stacks[0].[Outputs]' --output text

