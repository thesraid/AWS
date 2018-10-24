#!/bin/bash

echo "Switching region"
aws configure set region eu-west-2 --profile cliaccount

echo "Getting VPC ID"
vpcid=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query Vpcs[*].VpcId --output=text --profile cliaccount)

echo "Getting list of subnets"
SUBNETS=($(aws ec2 describe-subnets --query Subnets[*].SubnetId --output text --profile cliaccount))
aws ec2 describe-subnets --query Subnets[*].SubnetId --output text --profile cliaccount

for subnetid in "${SUBNETS[@]}"
do
   echo "Deleting subnet $subnetid"
   echo "aws ec2 delete-subnet --subnet-id $subnetid --profile cliaccount"
   aws ec2 delete-subnet --subnet-id $subnetid --profile cliaccount
done

echo "Getting gateways"
GATEWAYS=($(aws ec2 describe-internet-gateways --query InternetGateways[*].InternetGatewayId --output text --profile cliaccount))
for gatewayid in "${GATEWAYS[@]}"
do
   echo "Detaching gateway $gatewayid"
   aws ec2 detach-internet-gateway --internet-gateway-id $gatewayid --vpc-id $vpcid --profile cliaccount
   echo "Deleting gateway $gatewayid"
   aws ec2 delete-internet-gateway --internet-gateway-id $gatewayid --profile cliaccount
done

echo "Deleting VPC $vpcid"
aws ec2 delete-vpc --vpc-id $vpcid --profile cliaccount
