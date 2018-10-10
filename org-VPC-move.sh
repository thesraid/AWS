#!/bin/bash
# joriordan@alienvault.com
function usage
{
    echo "usage: org-new-acc.sh [-h] 
				      --account_name [-n] ACCOUNT_NAME
                                      --accountId [-i] ACCOUNT_ID"
}

newAccName=""
accId=""
profile=""
roleName="OrganizationAccountAccessRole"
destinationOUname="Students"
regions=(eu-west-1 us-east-1)

while [ "$1" != "" ]; do
    case $1 in
        -n | --account_name )   shift
                                newAccName=$1
                                ;;
        -i | --accountId )  	shift
                                accId=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

profile=$newAccName

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
  accID=$(aws organizations list-accounts --output text --query 'Accounts[?Name==`$newAccName`]'.Id)
  rootOU=$(aws organizations list-roots --query 'Roots[0].[Id]' --output text)
  destOU=$(aws organizations list-organizational-units-for-parent --parent-id $rootOU --query 'OrganizationalUnits[?Name==`'$destinationOUname'`].[Id]' --output text)

  printf "accID:$accID\n"
  printf "rootOU:$rootOU\n"
  printf "destOU:$destOU\n"

  aws organizations move-account --account-id $accID --source-parent-id $rootOU --destination-parent-id $destOU 
  if [ $? -ne 0 ]
  then
    printf "Moving Account Failed\n"
  fi
fi

echo New Account ID is $accID

