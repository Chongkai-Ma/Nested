#! /usr/bin/expect 
#login use SSH

#This is written by choma at 9th/Jan/2019


proc SSH { Password }  {  set timeout 180
        expect {
                "*yes/no*" { send "yes\r";exp_continue }
                "*assword*" { send "$Password\r";exp_continue }
                "*#*" { send_user "\r\r\r\r\rLogin Success\r\r\r\r\r" }
                timeout { send_user "\r\r\r\r\rLogin Timeout\r\r\r\r\r";exit 1 }
        }

}

set HostIP [lindex $argv 0]
set url    [lindex $argv 1]


set timeout -1 

exec sh -c { rm -f /root/.ssh/know_hosts }

#clean the environment
spawn ssh root@$HostIP
SSH "redhat"
#SSH "kvmautotest"

send "rm -rf /home/nested-autoshell/ \r"
expect "*#*"
sleep 1 
send "exit \r"

#copy the whole code to the host
spawn scp -r ../L1-rhel8_L2-rhel8/ root@$HostIP:/home/nested-autoshell/
SSH "redhat"
#SSH "kvmautotest"

#login the host
spawn ssh root@$HostIP
SSH "redhat"
#SSH "kvmautotest"

send "cd /home/nested-autoshell&&wget ${url}isolinux/initrd.img ${url}isolinux/vmlinuz&&qemu-img create --object secret,id=sec0,data=redhat -f luks -o key-secret=sec0 nested.luks 300G \r"

expect "*#*"
sleep 2
send "sh /home/nested-autoshell/l1_install.sh $url \r"
puts "***L1 guest is booting, please wait ... "
sleep 90

expect "refresh]: "
sleep 2
send "2\r"
expect ": "
sleep 1
send "2\r"
expect ": "
sleep 1
send "1\r"
expect ": "
sleep 1
send "2\r"
expect "Press ENTER to continue*"
sleep 1
send "\r"
expect ": "
sleep 1
send "64\r"
expect ": "
sleep 1
send "5\r"
expect ": "
sleep 1
send "c\r"
expect ": "
sleep 1
send "1\r"
expect ": "
sleep 1
send "c\r"
expect ": "
sleep 1
send "c\r"
expect ": "
send "8\r"
expect "Password: "
sleep 1
send "redhat\r"
expect "Password (confirm): "
sleep 1
send "redhat\r"
sleep 1
expect "Please respond 'yes' or 'no': "
sleep 1
send "yes\r"
expect ": "
sleep 2
send "r\r"

expect ": "
send "b\r"

expect "Press * to quit*"
send "\r"
send "\r"

sleep 10
exit 0
