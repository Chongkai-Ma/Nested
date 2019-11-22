#! /usr/bin/expect  
#Login use SSH

set timeout -1

proc SSH { Password }  {  set timeout 180
	expect {
		"*yes/no*" { send "yes\r";exp_continue }
		"*assword*" { send "$Password\r";exp_continue }
		"*#*" { send_user "\r\r\r\r\rLogin Success\r\r\r\r\r" }
		timeout { send_user "\r\r\r\r\rLogin Timeout\r\r\r\r\r";exit 1 }
	}

}


set HostIP [lindex $argv 0]
set cpuL2 [lindex $argv 1]
set url [lindex $argv 2]



#This code is written by choma at 9th/Jan/2019


set timeout -1

#Login the host
spawn ssh root@$HostIP
SSH "redhat"
#SSH "kvmautotest"

send "rm -f /root/.ssh/known_hosts\r"
expect "*#*"
send "rm -f /home/nested-autoshell/hostLog.out \r"
expect "*#*"
send "touch /home/nested-autoshell/hostLog.out \r"
expect "*#*"
send "chmod 777 /home/nested-autoshell/hostLog.out \r"
expect "*#*"
sleep 5
#start the L1 guest:
puts "Now the L1 guest is booting, Please wait a second ... ... "
send "nohup sh /home/nested-autoshell/l1_start.sh  | tee /home/nested-autoshell/hostLog.out &\r"
sleep 180
send "\r"


#Find L1 guest IP addr
spawn ssh root@$HostIP
SSH "redhat"
send "nmap -sP $HostIP/22|grep -i 52:54:69:B5:35:15 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
set L1GuestIP "$expect_out(1,string)"


#clean the environment
spawn ssh root@$L1GuestIP
SSH "redhat"
#SSH "kvmautotest"

send "rm -rf /home/nested-autoshell/ \r"
expect "*#*"
sleep 1
send "exit \r"


#download the packags and repo
spawn scp -r -p ../L1-rhel8_L2-rhel8/ root@$L1GuestIP:/home/nested-autoshell/
SSH "redhat"
#SSH "kvmautotest"

spawn scp root@$HostIP:/etc/yum.repos.d/* root@$L1GuestIP:/etc/yum.repos.d/
SSH "redhat"
#SSH "kvmautotest"


#login the guest-----
spawn ssh root@$L1GuestIP
SSH "redhat"
#SSH "kvmautotest"

set timeout -1

#Bug 1655899------
#send "depmod  \r"
#expect "*#*"

#send "modprobe -r kvm_intel \r"
#expect "*#*"
#send "modprobe kvm_intel \r"
#expect "*#*"

send "lsmod | grep kvm \r"
expect "*#*"

#setted up the L1 guest
sleep 2

send "yum -y install wget net-tools network-scripts vim psmisc nmap \r"
expect "*#*"
sleep 2

send "systemctl stop firewalld \r"
expect "*#*"
send "systemctl disable firewalld \r"
expect "*#*"
send "setenforce 0 \r"
expect "*#*"

sleep 10

#setted up the bridge
send "sh /home/nested-autoshell/SwitchSetup.sh $L1GuestIP  \r"
expect "*#*"
sleep 1
send "systemctl restart network \r"
expect "*#*"
send "ifconfig \r"
expect "*#*"
sleep 20

send "cd /home/nested-autoshell \r"
expect "*#*"

send "rpm -ivh bridge-utils-1.6-1.el8+7.x86_64.rpm \r"
expect "*#*"

#Install qemu-kvm
send "cd /etc/yum.repos.d/ \r"
expect "*#*"
send "dnf -y module install virt:8.0.0 \r"
expect "*#*"
sleep 2 

send "cd /home/nested-autoshell/qemu-kvm/&&yum -y install qemu-* \r"
expect "*#*"
sleep 2 

send "rpm -qa | grep qemu \r"
expect "*#*"

send "cd /home/nested-autoshell&&wget ${url}isolinux/initrd.img ${url}isolinux/vmlinuz&&qemu-img create --object secret,id=sec0,data=redhat -f luks -o key-secret=sec0 nested-L2.luks 30G \r"

expect "*#*"
sleep 2

puts "Now the L2 guest is booting, that will take 2 mins, please wait .... "
send "sh /home/nested-autoshell/l2_install.sh $cpuL2 $url \r"
sleep 100

expect "refresh]: "
sleep 2
send "2\r"
expect ": "
sleep 2
send "2\r"
expect ": "
sleep 2
send "1\r"
expect ": "
sleep 2
send "2\r"
expect "Press ENTER to continue*"
sleep 2
send "\r"
expect ": "
sleep 2
send "64\r"
expect ": "
sleep 2
send "5\r"
expect ": "
sleep 2
#if the process do not select the disk, please remove the reference.

send "1\r"
expect ": "
sleep 2

send "c\r"
expect ": "
sleep 2
send "1\r"
expect ": "
sleep 2
send "c\r"
expect ": "
sleep 2
send "c\r"
expect ": "
send "8\r"
expect "Password: "
sleep 2
send "redhat\r"
expect "Password (confirm): "
sleep 2
send "redhat\r"
sleep 2
expect "Please respond 'yes' or 'no': "
sleep 2
send "yes\r"
expect ": "
sleep 2
send "r\r"

expect ": "
send "b\r"

expect "Press * to quit*"
send "\r"
send "\r"

sleep 60
exit 0

