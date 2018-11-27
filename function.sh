#!/bin/bash

function go
{
return 0
}

result=$(go)
if [ $? -ne 0 ]
then
  printf "Error occured connecting to the account\n"
  exit 1
fi

