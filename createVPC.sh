#/bin/bash
# joriordan@alienvault.com
function usage
{
    echo "usage: createVPC.sh [-h]
			      --region [-r] REGION
                              --cl_profile_name [-c] CLI_PROFILE_NAME"
}


while [ "$1" != "" ]; do
    case $1 in
        -c | --cl_profile_name ) shift
                                profile=$1
                                ;;
        -r | --region ) 	shift
                                region=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$profile" = "" ] || [ "$region" = ""  ]
then
  usage
  exit
fi

aws configure set region $region --profile $profile

aws ec2 create-vpc --cidr-block 192.168.250.0/24 --profile $profile > /dev/null 2>&1
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
