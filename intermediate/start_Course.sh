#!/bin/bash

# joriordan

# Prints the script usage information
function usage
{
    echo "usage: startCourse [-h]
                                      --account_name [-a] ACCOUNT_NAME	Multiple accounts can be specified in quotes
                                      --password [-p] PASSWORD
                                      --region [-r] REGION 		us-east-1
                                      --course [-c] COURSE 		ANYDC ANYSA CENSP
                                      --sensor [-s] yes/no
                                      --tag [-t] TAG 			Alphanumeric with dashes only"
}

# This is the name of the role in the Parent Org that has permissions to do things in the child orgs. It's set up in the child orgs when they are created. 
role="OrganizationAccountAccessRole"
# This is the directory into which all students orgs are organised. There are other OUs for partner demo environments and so on.
destinationOUname="Students"

# Instansiate some variables
accName=""
region=""
course=""
url=""
tag=$(date +"%b-%d")

# Read the input from the command. 
while [ "$1" != "" ]; do
    case $1 in
        -a | --account_name )   shift
                                accNameArray=($1)
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
        -s | --sensor )         shift
                                sensor=$1
                                ;;
        -t | --tag )            shift
                                tag=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done


for accName in "${accNameArray[@]}"
do

# Username and Group Name will match the sub Org name
userName=$accName
groupName=$accName
# This policy specifies what resources the user can access. It should be in the same folder as the script
UserPolicy="file:///opt/avorgcreator/policies/StudentPolicy.json"
# This policy specifies what region the user can access. It should be in the same folder as the script
LocationPolicy="file:///opt/avorgcreator/policies/$region.json"



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

# Profiles are what the AWS CLI uses to identify which sub Org you want to run a command in. We will call the profile after the account name with the word Profile at the end
profile=$accName
printf "Profile name is now $profile\n"

# If a password wasn't supplied when the script was run prompt for one
if [ "$userPassword" = "" ]
then
   printf "\nEnter desired user password : "
   read userPassword
   printf "\n"
fi

# If a region wasn't supplied when the script was run prompt for one. Only prompt for regions where AMI Images for a course exist. 
# This is done manually
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

# Get a ticket to allow us to use the role that was created in the sub Orgs during their creation
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

# Prompt for a course to launch if it wasn't included in the command
if [ "$course" = "" ]
then
   printf "\nAvailable courses\n"
   printf "   ANYDC\n"
   printf "   ANYSA\n"
   printf "   CENSP\n"
   printf "\nChoose the course : "
   read course
   printf "You chose $course\n"
fi

# Ensure it's a vaild choice
if [ "$course" != "ANYDC" ] && [ "$course" != "ANYSA" ]  && [ "$course" != "CENSP" ]
then
   printf "Invalid course\n"
   exit
fi

# Prompt for sensor deployment if it wasn't included in the command
if [ "$sensor" = "" ]
then
   printf "\nWould you like to deploy a Sensor? Please type yes or no\n"
   read sensor
   # convert the answer to lowercase to cut down on the number of variations
   printf "You chose $sensor\n"
fi

sensor=$(echo "$sensor" | tr '[:upper:]' '[:lower:]')

# Ensure it's a vaild choice
if [ "$sensor" != "y" ] && [ "$sensor" != "yes" ] && [ "$sensor" != "n" ] && [ "$sensor" != "no" ]
then
   printf "Invalid sensor choice\n"
   exit
fi

# Since we may be deploying multiple cloudformation templates (for example including a sensor) it is a function that can be called.
# The function has to be called from below where the fuction is written.

deploy_template () {

   # When calling the cuntion 3 pieces of information will be included in this order 
   # stackName (course) 
   # Template URL
   # Parameters to pass to the template
   stackName="$1"
   url=$2
   parameter="$3"

   # If you try and connect to the CloudFormation service immediately it might fail.
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
   printf "\nCreating $stackName Stack Under New Account\n"

   # Create the stack and pass the VPC id and URL from above.
   aws cloudformation create-stack --stack-name $stackName --template-url $url --parameters $parameter --capabilities CAPABILITY_IAM --profile $profile > /dev/null
   if [ $? -ne 0 ]
   then
     printf "$stackName Stack Failed to Create\n"
     exit 1
   fi

   # Loop until the stack status is CREATE_COMPLETE. If we get an error status then error out
   printf "Waiting for $stackName stack to start ..."
   cfStat=$(aws cloudformation describe-stacks --stack-name $stackName --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
   while [ $cfStat != "CREATE_COMPLETE" ]
   do
     sleep 5
     printf "."
     cfStat=$(aws cloudformation describe-stacks --stack-name $stackName --profile $profile --query 'Stacks[0].[StackStatus]' --output text)
     if [ $cfStat = "CREATE_FAILED" ] || [ $cfStat = "ROLLBACK_COMPLETE"  ]
     then
       printf "\n$stackName Stack failed to start\n"
       printf "ERROR : $cfStat\n"
       aws cloudformation describe-stacks --stack-name $stackName --profile $profile
       aws cloudformation describe-stack-events --no-paginate --stack-name $stackName --profile $profile > error-$profile-$stackName.txt
       printf "\n\n*** View error-$profile-$stackName.txt for more detailed error information ***\n"
       printf "*** *** ***            Error file is read from the bottom up       *** *** ***\n"
       exit 1
     fi
   done
   printf "\n$stackName started\n"

# End of deploy_sensor function
}

# Choose the appropriate CloudFormation json
if [ "$course" = "ANYDC" ]
then
  url="https://s3-eu-west-1.amazonaws.com/deploy-student-env/ANYDC.json"
  
  # Set the paratmer variables that need to be sent this cloud formation template

  # Each Sub Org has a different VPC ID. The Cloudformation template needs to know which VPC to deploy into so we need to grab the VPC ID first
  # Each Sub Org only has one VPC called TrainingVPC. The default VPC has been removed from each subOrg for security reasons
  vpcid=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[*].VpcId --output=text --profile $profile)

  # Build the parameter variable for the ANYDC course
  parameter="ParameterKey=TrainingVPC,ParameterValue=$vpcid"

  deploy_template "$course-$tag" $url $parameter

fi

if [ "$course" = "ANYSA" ]
then
  url="https://s3-eu-west-1.amazonaws.com/deploy-student-env/ANYSA.json"
fi

if [ "$course" = "CENSP" ]
then
  url="https://s3-eu-west-1.amazonaws.com/deploy-student-env/CENSP.json"

  # Set the paratmer variables that need to be sent this cloud formation template

  # Each Sub Org has a different VPC ID. The Cloudformation template needs to know which VPC to deploy into so we need to grab the VPC ID first
  # Each Sub Org only has one VPC called TrainingVPC. The default VPC has been removed from each subOrg for security reasons
  vpcid=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[*].VpcId --output=text --profile $profile)

  # Build the paramter variable for the course
  parameter="ParameterKey=TrainingVPC,ParameterValue=$vpcid"
  
  deploy_template "$course-$tag" $url $parameter

fi

if [ "$sensor" = "yes" ] || [ "$sensor" = "y" ]
then
  url="https://s3.amazonaws.com/downloads.alienvault.cloud/usm-anywhere/sensor-images/usm-anywhere-sensor-aws-vpc.template"

  # The sensor cloudformatin template is provided by AlienVault. To deploy it it needs
  # A Key - Which we will have to create
  # The VPC ID - Each Sub Org has a different VPC ID. The Cloudformation template needs to know which VPC to deploy into so we need to grab the VPC ID first
  # The NodeName - We will just call it Sensor
  # The SubnetID - Each Sub Org has a different SubnetID. The Cloudfomration template needs to know which Subnet to deploy into so we need to grab the Subnet ID first

  # Creating the key
  aws ec2 create-key-pair --key-name Sensor --profile $profile > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    printf "Failed to create SSH Key\n"
  exit 1
  fi

  # Getting the VPC ID
  vpcid=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[*].VpcId --output=text --profile $profile)

  # Getting the subnet ID - Each VPC should only have one subnet so we don't need to worry about multiple results here
  subnetid=$(aws ec2 describe-subnets --query Subnets[*].SubnetId --output=text --profile $profile)

  if [ "$subnetid" = "" ]
  then
     printf "Error: No subnet found. Did you deploy a course lab? Exiting...... Account cleanup required\n"
     exit 1
  fi

  parameter="ParameterKey=VpcId,ParameterValue=$vpcid ParameterKey=KeyName,ParameterValue=Sensor ParameterKey=SubnetId,ParameterValue=$subnetid ParameterKey=NodeName,ParameterValue=Sensor"

  # The parameter variable has to be in quotes as it contains spaces. If the quotes aren't there it get's parsed up to the first space only
  deploy_template Sensor $url "$parameter"

  # Now that the sensor is deployed lets open it up to local traffic
  sgid=$(aws ec2 describe-security-groups --query SecurityGroups[*].GroupId --filter Name=description,Values="Enable USM Services Connectivity" --output text --profile $profile)
  aws ec2 authorize-security-group-ingress --group-id $sgid --cidr 192.168.250.0/24 --protocol all --profile $profile
  if [ $? -ne 0 ]
  then
    printf "Failed to add rule to Security Group to allow local inblound traffic to Sensor\n"
  exit 1
  fi

   
fi

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

echo "-------------------------------------------------------------------" >> results.txt
echo $tag >> results.txt
date >> results.txt
printf "Students can now log into the $accID account with the information below\n" | tee -a results.txt
printf "URL  : https://console.aws.amazon.com/console/home?region=$region\n" | tee -a results.txt
printf "ACC  : ${profile,,}\n" | tee -a results.txt
printf "USER : ${userName,,}\n" | tee -a results.txt
printf "PASS : $userPassword\n" | tee -a results.txt

# Print out any other output from the class CloudFormation template. 
aws cloudformation describe-stacks --stack-name "$course-$tag" --profile $profile --query 'Stacks[0].[Outputs]' --output text | tee -a results.txt

if [ "$sensor" = "yes" ] || [ "$sensor" = "y" ]
then
   printf "Sensor Internal: " | tee -a results.txt
   aws ec2 describe-instances --query Reservations[*].Instances[*].PrivateIpAddress --filters Name=tag:Name,Values=Sensor --output text --profile $profile | tee -a results.txt
   printf "Sensor External: " | tee -a results.txt
   aws ec2 describe-instances --query Reservations[*].Instances[*].PublicIpAddress --filters Name=tag:Name,Values=Sensor --output text --profile $profile | tee -a results.txt
  
fi
printf "\n"

done
