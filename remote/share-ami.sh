#!/bin/bash

# joriordan

# Prints the script usage information
function usage
{
    echo "share-ami [-h] 
          --subs [-s] LIST_OF_SUBORGS_TEXTFILE
          --region [-r] REGION"
}

# Read the input from the command.
while [ "$1" != "" ]; do
    case $1 in
        -s | --subs )	   	shift
                                subs=$1
                                ;;
        -r | --region )         shift
                                region=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    shift
done

echo " "
echo "This will update ALL images in $region to only allow access from the SubOrgs specified. Hit Ctrl+C to cancel"
echo "5"
sleep 1
echo "4"
sleep 1
echo "3"
sleep 1
echo "2"
sleep 1
echo "1"
sleep 1

IMAGES=($(aws ec2 describe-images --owners self --query 'Images[*].[ImageId]' --output text --region $region))
for image in "${IMAGES[@]}"
do
   printf "Modifying "
   aws ec2 describe-images --owners self --query 'Images[*].[Name,ImageId]' --output text --region $region | grep $image
   aws ec2 modify-image-attribute --image-id $image --launch-permission "{\"Remove\": [{\"Group\":\"all\"}]}" --region $region

   SUBS=($(cat $subs))
   for sub in "${SUBS[@]}"
   do
      printf "."
      aws ec2 modify-image-attribute --image-id $image --launch-permission "Add=[{UserId=$sub}]" --region $region
   done

   echo " "
done
