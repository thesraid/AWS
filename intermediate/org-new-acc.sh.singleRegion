#!/bin/bash
# joriordan@alienvault.com
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
profile=""
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
                                profile=$1
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

if [ "$newAccName" = "" ] || [ "$newAccEmail" = "" ] || [ "$profile" = "" ] || [ "$destinationOUname" = "" ] || [ "$region" = "" ] || [ "$userName" = "" ] || [ "$userPassword" = "" ] || [ "$groupName" = "" ] || [ "$policy" = "" ]
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
aws configure set region $region --profile $profile
aws configure set role_arn $accARN --profile $profile
aws configure set source_profile default --profile $profile

printf "Creating User Login Profile\n"
printf "Creating a new user\n"
aws iam create-user --user-name $userName --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured creating a user\n"
  exit 1
fi

printf "Creating a new group\n"
aws iam create-group --group-name $groupName --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured creating a group\n"
  exit 1
fi

printf "Adding the user to the group\n"
aws iam add-user-to-group --user-name $userName --group-name $groupName --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured adding the user to the group\n"
  exit 1
fi

printf "Applying the Policy\n"
aws iam put-user-policy --user-name $userName --policy-name StudentRole --policy-document $policy --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured assigning the policy to the user\n"
  exit 1
fi

printf "Giving user a login password\n"
aws iam create-login-profile --user-name $userName --password $userPassword --profile $profile > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured setting the users login and password\n"
  exit 1
fi

printf "Created User\n"

printf "Creating VPC\n"
sleep 20

aws ec2 create-vpc --cidr-block 192.168.250.0/24 --profile $profile  > /dev/null 2>&1
if [ $? -ne 0 ]
then
  printf "Error occured creating VPC\n"
  exit 1
fi

vpcid=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[*].VpcId --output=text --profile $profile)
aws ec2 create-tags --resources $vpcid --tags Key=Name,Value=TrainingVPC --profile $profile > /dev/null 2>&1 
if [ $? -ne 0 ]
then
  printf "Error occured naming VPC\n"
  exit 1
fi

printf "VPC Created\n"


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

