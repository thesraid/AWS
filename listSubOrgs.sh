#!/bin/bash
#aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m
aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --output text --query 'Accounts[*].[Name,Id]' | sort -n
