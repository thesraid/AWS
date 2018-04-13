#!/bin/bash
# joriordan@alienvault.com
function usage
{
    echo "usage: organization_new_acc.sh [-h] 
				      --account_name [-n] ACCOUNT_NAME
                                      --account_email [-e] ACCOUNT_EMAIL
                                      --cl_profile_name [-c] CLI_PROFILE_NAME
                                      [--region [-r] AWS_REGION]"
}

newAccName=""
newAccEmail=""
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
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$newAccName" = "" ] || [ "$newAccEmail" = "" ] || [ "$newProfile" = "" ] || [ "$region" = "" ] 
then
  usage
  exit
fi

accARN="arn:aws:iam::$accID:role/$roleName"

printf "\nCreate New CLI Profile\n"
aws configure set region $region --profile $newProfile
aws configure set role_arn $accARN --profile $newProfile
aws configure set source_profile default --profile $newProfile

printf "\nCreating VPC\n"
vpc-id=$(aws ec2 create-vpc --cidr-block 192.168.250.0/24 --profile $newProfile)
if [ $? -ne 0 ]
then
  printf "VPC Creation failed\n"
fi

aws ec2 create-tags --resources $vpc-id --tags Key=Name,Value=CFVPC --profile $newProfile
if [ $? -ne 0 ]
then
  printf "VPC Creation failed\n"
fi

