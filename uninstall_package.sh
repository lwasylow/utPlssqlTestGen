#!/bin/bash

target_user=$1
target_user_password=$2
testdb=$3

###Install Package
echo "UnInstall Framework"
sqlplus "${target_user}"/"${target_user_password}"@"${testdb}" @uninstallobjects.sql "${target_user}" > uninstall.log
