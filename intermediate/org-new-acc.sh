#!/bin/bash
# joriordan@alienvault.com
function usage
{
    echo "usage: org-new-acc.sh [-h] 
				      --account_name [-n] ACCOUNT_NAME
                                      --account_email [-e] ACCOUNT_EMAIL
     EXAMPLE: ./org-new-acc.sh -n AVStudent30 -e avstudent30@alien-training.com"
}

newAccName=""
newAccEmail=""
profile=""
roleName="OrganizationAccountAccessRole"
destinationOUname="Students"
regions=(eu-west-1 us-east-1)

while [ "$1" != "" ]; do
    case $1 in
        -n | --account_name )   shift
                                newAccName=$1
                                ;;
        -e | --account_email )  shift
                                newAccEmail=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$newAccName" = "" ] || [ "$newAccEmail" = "" ] 
then
  usage
  exit
fi

profile=$newAccName

printf "Creating a new account called $newAccName\n"
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

printf "\nCreating New CLI Profile\n"
aws configure set role_arn $accARN --profile $profile
aws configure set source_profile default --profile $profile

printf "Waiting for account $accID to be fully spun up."
sleep 5
printf "."
sleep 5
printf "."
sleep 5
printf "."
sleep 5
printf ".\n"

printf "Giving the new account an alias of ${profile,,}\n"
aws iam create-account-alias --account-alias ${profile,,} --profile $profile


# We can't list the regions from this account as it's not created yet. So we will list them from cliaccount
regions=($(aws ec2 describe-regions --query Regions[*].RegionName --output text --profile cliaccount))

printf "Creating the TrainingVPC in each region while deleting the default VPC\n"
for region in "${regions[@]}"
do

   aws configure set region $region --profile $profile

   #printf "Creating Training VPC in $region \n"
   #sleep 20
   printf "."

   aws ec2 create-vpc --cidr-block 192.168.250.0/24 --profile $profile  > /dev/null 2>&1
   if [ $? -ne 0 ]
   then
      printf "Error occured creating TrainingVPC in $region\n"
      printf "******************************************************************************************\n"
      printf "This occurs when AWS does not verify the account quickly. It normally takes a few minutes but could take up to 48 hours."
      printf "Try running this command in a few minutes org-VPC-move.sh -n $newAccName -i $accID"
      printf "If this doesn't work you can create a user in the account using labCreateAdmin -p <Password> -a $newAccName"
      printf "Once you've logged in visit https://aws-portal.amazon.com/gp/aws/developer/registration/index.html and choose FREE"
      printf "Try running this command again org-VPC-move.sh -n $newAccName -i $accID"
      printf "Still no luck? Try again in a few hours or email aws-verification@amazon.com and ask them to verify the account $accID"
      printf "Once they've verified it run org-VPC-move.sh -n $newAccName -i $accID"
      printf "******************************************************************************************\n"
      echo " "
      exit 1
   fi

   vpcid=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[*].VpcId --output=text --profile $profile)
   aws ec2 create-tags --resources $vpcid --tags Key=Name,Value=TrainingVPC --profile $profile > /dev/null 2>&1
   if [ $? -ne 0 ]
   then
      printf "Error occured naming TrainingVPC in $region\n"
      exit 1
   fi


   #printf "Deleting Default VPC in $region\n"
   printf "."

   vpcid=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query Vpcs[*].VpcId --output=text --profile $profile)
   if [ $? -ne 0 ]
   then
      printf "Error getting Default VPC information in $region\n"
      exit 1
   fi

   SUBNETS=($(aws ec2 describe-subnets --query Subnets[*].SubnetId --output text --profile $profile))
   for subnetid in "${SUBNETS[@]}"
   do
      aws ec2 delete-subnet --subnet-id $subnetid --profile $profile
      if [ $? -ne 0 ]
      then
         printf "Error deleting default subnets in $region\n"
         exit 1
      fi
   done

   GATEWAYS=($(aws ec2 describe-internet-gateways --query InternetGateways[*].InternetGatewayId --output text --profile $profile))
   for gatewayid in "${GATEWAYS[@]}"
   do
      aws ec2 detach-internet-gateway --internet-gateway-id $gatewayid --vpc-id $vpcid --profile $profile
      if [ $? -ne 0 ]
      then
         printf "Error detaching default gateway in $region\n"
         exit 1
      fi

      aws ec2 delete-internet-gateway --internet-gateway-id $gatewayid --profile $profile
      if [ $? -ne 0 ]
      then
         printf "Error deleting default gateway in $region\n"
         exit 1
      fi
   done

   aws ec2 delete-vpc --vpc-id $vpcid --profile $profile
   if [ $? -ne 0 ]
   then
      printf "Error deleting default VPC in $region\n"
      exit 1
   fi

done

printf "\n"

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
echo " "
echo "Don't forget to update AMI permissions with share-ami-remote.sh when all of the new accounts have been succesfully created"
