#!/bin/bash

# joriordan

# Prints the script usage information
function usage
{
    echo "usage: start_Course.sh [-h] 
				      --account_name [-a] ACCOUNT_NAME
				      --password [-p] PASSWORD
				      --region [r] REGION
				      --course [-c] COURSE"
}

# Set some variables
accName=""

# This is the name of the role in the Parent Org that has permissions to do things in the child orgs. It's set up in the child orgs when they are created. 
role="OrganizationAccountAccessRole"
# This is the directory into which all students orgs are organised. There are other OUs for partner demo environments and so on.
destinationOUname="Students"
region=""
course=""
url=""

# Read the input from the command. 
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

# Username and Group Name will match the sub Org name
userName=$accName
groupName=$accName
# This policy specifies what resources the user can access. It should be in the same folder as the script
UserPolicy="file://StudentPolicy.json"
# This policy specifies what region the user can access. It should be in the same folder as the script
LocationPolicy="file://$region.json"



# If the accName was not specified then list the accounts and the user can choose one. 
# The parent ID of the OUs is hard coded into this command. If we move to a different AWS root org it will need to be updated. 
if [ "$accName" = "" ]
then
  aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[*].Name' 
  printf "Please enter the name of the account (with or without quotes) : "
  read accName
  # Remove quotes if entered
  accName=$(sed -e 's/^"//' -e 's/"$//' <<< $accName)
  printf "You chose $accName \n"
fi

# Get the account ID for the Account
accID=$(aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[?Name==`'$accName'`].Id' --output text)
if [ "$accID" = "" ] 
then
   printf "Invalid account\n"
   exit
fi
printf "The account ID for $accName is $accID\n"

# Profiles are what the AWS CLI uses to identify which sub Org you want to run a command in. We will call the profile after the account name
profile=$accName"Profile"
printf "Profile name is now $profile\n"

# If a password wasn't supplied when the script was run prompt for one
if [ "$userPassword" = "" ]
then
   printf "\nEnter desired user password : "
   read userPassword
   printf "\n"
fi

# If a region wasn't supplied when the script was run prompt for one. Only prompt for regions where AMI Images for a course exist. 
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

# If the region doesn't match one of the choices above then error out
if [ "$region" != "eu-west-1" ] && [ "$region" != "us-east-1" ]
then
   printf "Invalid region\n"
   exit
fi

# Get a ticket to allow use to use the role that was created in the sub Orgs during their creation
expiry=$(aws sts assume-role --role-arn arn:aws:iam::$accID:role/$role --query 'Credentials.Expiration' --role-session-name $profile)
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi

printf "Connection valid to $accName until $expiry\n"

# Set the region to the selected region. This ensures all following commands are run in the correct region. 
aws configure set region $region --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi

# Assume the role created in the Sub Orgs for the following commands
aws configure set role_arn arn:aws:iam::$accID:role/$role --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi

# Connect to the Sub Org
aws configure set source_profile default --profile $profile
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi

# Prompt for a course to launch
if [ "$course" = "" ]
then
   printf "\nAvailable courses\n"
   printf "   ANYDC\n"
   printf "   ANYSA\n"
   printf "   Sensor\n"
   printf "\nChoose the course : "
   read course
   printf "You chose $course\n"
fi

# Ensure it's a vaild choice
if [ "$course" != "ANYDC" ] && [ "$course" != "ANYSA" ]  && [ "$course" != "Sensor" ]
then
   printf "Invalid course\n"
   exit
fi

# Choose the appropriate CloudFormation json
if [ "$course" = "ANYDC" ]
then
  url="https://s3-eu-west-1.amazonaws.com/deploy-student-env/ANYDC.json"
  
  # Set the paratmer variables hat need to be sent this cloud formation template
  # Each Sub Org has a differnt VPC ID. The Cloudfomration template needs to know which VPC to deploy into so we need to grab the VPC ID first
  # Each Sub Org only has one VPC called TrainingVPC. The default VPC has been removed from each subOrg for security reasons
  vpcid=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[*].VpcId --output=text --profile $profile)

  # Build the paramter variable for the ANYDC course
  parameter="ParameterKey=TrainingVPC,ParameterValue=$vpcid"

fi

if [ "$course" = "ANYSA" ]
then
  url="https://s3-eu-west-1.amazonaws.com/deploy-student-env/ANYSA.json"
fi

if [ "$course" = "Sensor" ]
then
  url="https://s3.amazonaws.com/downloads.alienvault.cloud/usm-anywhere/sensor-images/usm-anywhere-sensor-aws-vpc.template"
fi



# If you try and connect to the CloudFormation service immeditely it might fail. 
# Run a read only command 10 times to see if it's up first
cfcntr=0
printf "Waiting for CloudFormation Service ..."
aws cloudformation list-stacks --profile $profile > /dev/null 2>&1
# Capture any errors as actOut
actOut=$?
# If there are errors then wait 5 seconds and try again
#  We will do this 10 times
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

# If we tried 10 times and it's still not answering then we give up
if [ $cfcntr -gt 10 ]
then
  printf "\nCloudFormation Service not available\n"
  exit 1
fi

# If it is up then we will go ahead and deploy the lab using the CloudFormation template url that we set above
printf "\nCreating Student Lab Under New Account\n"

# Create the stack and pass the VPC id and URL from above. 
aws cloudformation create-stack --stack-name $course --template-url $url --parameters $parameter --profile $profile > /dev/null 
if [ $? -ne 0 ]
then
  printf "Student Lab Failed to Create\n"
  exit 1
fi

# Loop until the stack status is CREATE_COMPLETE. If we get an error status then error out
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

# Create a user to allow the students access the account

printf "Creating a new user\n"
aws iam create-user --user-name $userName --profile $profile > /dev/null 
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
aws iam add-user-to-group --user-name $userName --group-name $groupName --profile $profile > /dev/null
if [ $? -ne 0 ]
then
  printf "Error occured adding the user to the group\n"
  exit 1
fi

printf "Assigning a policy to the Group\n"
aws iam put-group-policy --group-name $groupName --policy-name StudentRole --policy-document $UserPolicy --profile $profile > /dev/null
aws iam put-group-policy --group-name $groupName --policy-name LocationRole --policy-document $LocationPolicy --profile $profile > /dev/null
if [ $? -ne 0 ]
then
  printf "Error occured assigning the policy to the user\n"
  exit 1
fi

printf "Giving user a login password\n"
aws iam create-login-profile --user-name $userName --password $userPassword --profile $profile > /dev/null
if [ $? -ne 0 ]
then
  printf "Error occured setting the users login and password\n"
  exit 1
fi

printf "Students can now log into\n"
printf "URL  : https://console.aws.amazon.com/console/home?region=$region\n"
printf "ACC  : $accID\n"
printf "USER : $userName\n"
printf "PASS : $userPassword\n"

if [ "$course" == "ANYDC" ] || [ "$course" == "ANYSA" ]
then
   aws cloudformation describe-stacks --stack-name $course --profile $profile --query 'Stacks[0].[Outputs]' --output text
fi


