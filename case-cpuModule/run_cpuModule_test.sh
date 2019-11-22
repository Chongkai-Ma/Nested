#!/bin/bash

cat how_to_run_cpuModule_case

read -p "Do You Read the Above Information (yes/no): " n5
read -p "please enter the host IP address: " n1
read -p "select a cpuType of your host (intel or amd): " n2
read -p "select a cpuModule using on the L1 guest: " n3

HostIP=$n1
cpuType=$n2
cpuModule=$n3

./cpuModule.ctl $HostIP $cpuType $cpuModule
