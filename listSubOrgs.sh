#!/bin/bash
#aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m
aws organizations list-accounts-for-parent --parent-id ou-yus6-1nrdvs4m --query 'Accounts[*].[Name,Id]'
