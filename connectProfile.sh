#!/bin/bash
function usage
{
    echo "
usage: new_user.sh [-h]	--account_id [-a] ACCOUNTID
                        --cl_profile_name [-c] CLI_PROFILE_NAME
			( --role [-r] ROLE )
"
}

account=""
role=""
cliProfile=""

while [ "$1" != "" ]; do
    case $1 in
        -a | --account )   	shift
                                account=$1
                                ;;
        -r | --role )        	shift
                                role=$1
                                ;;
        -c | --cl_profile_name ) shift
                                cliProfile=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

if [ "$account" = "" ] || [ "$cliProfile" = "" ]
then
  usage
  printf "Account         "
  printf "ID\n"
  aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --output text --query 'Accounts[*].[Name,Id]'
  exit
fi

if [ "$role" = "" ]
then
  role="OrganizationAccountAccessRole"
fi


echo ACC : $account
echo ROLE: $role
echo CLI : $cliProfile

aws sts assume-role --role-arn arn:aws:iam::$account:role/$role --role-session-name $cliProfile
aws configure set region eu-west-1 --profile $cliProfile
aws configure set role_arn arn:aws:iam::$account:role/$role --profile $cliProfile
aws configure set source_profile default --profile $cliProfile
