#!/bin/bash

target_user=$1
target_user_password=$2
testdb=$3

###Install Package
echo "Install Framework"
sqlplus "${target_user}"/"${target_user_password}"@"${testdb}" @installobjects.sql "${target_user}" > install.log
