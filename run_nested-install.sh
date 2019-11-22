#! /usr/bin/bash

cat how_to_run_this_scripts_text 

read -p "Do you read above information(yes/no): " n5
read -p "please enter the host IP address:" n1
read -p "please enter a L2 CPU module:" n2
read -p "please enter a repo URL:" n3

HostIP=$n1
cpuL2=$n2
url=$n3


echo " " > /root/.ssh/known_hosts

./install_l1.ctl $HostIP $url

if [ $? -ne 0 ]; then
        echo "L1 installation failed, please check the code and log ...."
	sleep 5s
	./install_l1.ctl $HostIP $url
else
        echo "L1 installation successed, installing L2 ..."
        ./install_l2.ctl $HostIP $cpuL2 $url 

fi


if [ $? -eq 0 ]; then

        echo "successfully install L1 and L2 !!"
        sleep 2m
        exit 0
else
        echo "L2 failed!"

fi

