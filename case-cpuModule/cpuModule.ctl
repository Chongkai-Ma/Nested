#! /usr/bin/expect

#this scripts is wrotten by choma at 14th Feb. 
#this the cpuModule case scripts. 
#If you want to execute the scripts. First of all, you need to input the HostIP address. The second one you need to input the cpuType, such as intel or AMD. Then, you need to input the cpuModule, such as the Skylake-Client or SandyBridge. 



###################################################
#login use SSH

proc SSH { Password } { set timeout 180
        expect {
                "*yes/no*"  { send "yes\r";exp_continue }
                "*assword*" { send "$Password\r";exp_continue }
                "*#*"       { send_user "\r\r\r\r\rLogin Success\r\r\r\r\r" }
		"*No route to host"      { puts "***TEST FAIL*** ***Can not connect the L2 guest, please check the $cpuModuleSele($i) Log***";exit 1 }
                timeout     { send_user "\r\r\r\r\rLogin Timeout\r\r\r\r\r";exit 1 }
        }

}



#set the variate of the input:
set HostIP     [lindex $argv 0]
set cpuType    [lindex $argv 1]
set cpuModule  [lindex $argv 2]

#using the variate set the table:
set cpu_intel(0) "Conroe"
set cpu_intel(1) "Nehalem"
set cpu_intel(2) "Penryn"
set cpu_intel(3) "Westmere"
set cpu_intel(4) "SandyBridge"
set cpu_intel(5) "cpu64-rhel6"
set cpu_intel(6) "IvyBridge"
set cpu_intel(7) "Haswell"
set cpu_intel(8) "Broadwell"
set cpu_intel(9) "Skylake-Client"
set cpu_intel(10) "Icelake-Client"
#set cpu_intel(11) "n270"

set cpu_amd(0) "Opteron_G1"
set cpu_amd(1) "Opteron_G2"
set cpu_amd(2) "Opteron_G3"
set cpu_amd(3) "Opteron_G4"
set cpu_amd(4) "Opteron_G5"

#never time out
set timeout -1

exec sh -c { rm -f /root/.ssh/known_hosts}


#clean the environment:
spawn ssh root@$HostIP
SSH "redhat"
#SSH "kvmautotest""

send "rm -f /root/.ssh/known_hosts\r"
expect "*#*"
send "rm -rf /home/nested-autoshell/case-cpuModule/* \r"
expect "*#*"
send "exit \r"

#update the new code:
spawn scp -r -p ../case-cpuModule/ root@$HostIP:/home/nested-autoshell/
SSH "redhat"
#SSH "kvmautotest"

#login the host and boot the L1 guest:
spawn ssh root@$HostIP
SSH "redhat"
#SSH "kvmautotest"

send "touch /home/nested-autoshell/case-cpuModule/case-cpuModuleLog.out \r"
expect "*#*"
#send "chmod 777 /home/nested-autoshell/case-cpuModule/case-cpuModuleLog.out \r"
#expect "*#*"
sleep 5
puts "***Now L1 is booting, please wait ...***"


if { $cpuType == "intel" } {
	send "nohup sh /home/nested-autoshell/case-cpuModule/boot-intelL1Guest.sh $cpuModule | tee /home/nested-autoshell/case-cpuModule/case-cpuModuleLog.out &\r"
} else {
	send "nohup sh /home/nested-autoshell/case-cpuModule/boot-amdL1Guest.sh $cpuModule | tee /home/nested-autoshell/case-cpuModule/case-cpuModuleLog.out &\r"
}

sleep 180
send "\r"


#Find L1 guest IP addr:
spawn ssh root@$HostIP
SSH "redhat"
send "nmap -sP $HostIP/22|grep -i 52:54:69:B5:35:15 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
set L1GuestIP "$expect_out(1,string)"


#clean the environment and download the packages
spawn ssh root@$L1GuestIP
SSH "redhat"
#SSH "kvmautotest"
send "rm -rf /home/nested-autoshell/cpu-Module \r"
expect "*#*"
sleep 1
send "exit \r"

spawn scp -r -p ../case-cpuModule root@$L1GuestIP:/home/nested-autoshell/cpu-Module
SSH "redhat"
#SSH "kvmautotest"


#login the L1 guest:
spawn ssh root@$L1GuestIP
SSH "redhat"
#SSH "kvmautotest"

puts "***Now this is L1 cpu module***"
send "lscpu\r"
expect "*#*"
sleep 5


set timeout -1


#start the test loop:

if { $cpuType == "amd" } {
	if { $cpuModule == "Opteron_G5" } {
		for { set i 0 } { $i<5 } { incr i } {
			set cpuModuleSele($i) $cpu_amd($i)
			#Now start the L2 guest loop and the cpu module start with "Opteron_G5":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-amdL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Opteron_G4" } {
		for { set i 0 } { $i<4 } { incr i } {
			set cpuModuleSele($i) $cpu_amd($i)
			#Now start the L2 guest loop and the cpu module start with "Opteron_G4":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-amdL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Opteron_G3" } {
		for { set i 0 } { $i<3 } { incr i } {
			set cpuModuleSele($i) $cpu_amd($i)
			#Now start the L2 guest loop and the cpu module start with "Opteron_G3":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-amdL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Opteron_G2" } {
		for { set i 0 } { $i<2 } { incr i } {
			set cpuModuleSele($i) $cpu_amd($i)
			#Now start the L2 guest loop and the cpu module start with "Opteron_G2":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-amdL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Opteron_G1" } {
		for { set i 0 } { $i<1 } { incr i } {
			set cpuModuleSele($i) $cpu_amd($i)
			#Now start the L2 guest loop and the cpu module start with "Opteron_G1":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-amdL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} else {
		puts "The CPU module is wrong, please try again."

	}


} else {
	if { $cpuModule == "Icelake-Client" } {
		for { set i 0 } { $i<11 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "Icelake-Client":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Skylake-Client" } {
		for { set i 0 } { $i<10 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "Skylake-Client":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
                }
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Broadwell" } {
		for { set i 0 } { $i<9 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "Broadwell":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Haswell" } {
		for { set i 0 } { $i<8 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "Haswell":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "IvyBridge" } {
		for { set i 0 } { $i<7 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "IvyBridge":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "cpu64-rhel6" } {
		for { set i 0 } { $i<6 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "cpu64-rhel6":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "SandyBridge" } {
		for { set i 0 } { $i<5 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "SandyBridge":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Westmere" } {
		for { set i 0 } { $i<4 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "Westmere":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Penryn" } { 
		for { set i 0 } { $i<3 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "Penryn":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Nehalem" } { 
		for { set i 0 } { $i<2 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "Nehalem":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} elseif { $cpuModule == "Conroe" } {
		for { set i 0 } { $i<1 } { incr i } {
			set cpuModuleSele($i) $cpu_intel($i)
			#Now start the L2 guest loop and the cpu module start with "Conroe":
			send "rm -rf /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			send "touch /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out \r"
			expect "*#*"
			puts "***Now L2 is booting, please wait...***"
			send "nohup sh /home/nested-autoshell/cpu-Module/boot-intelL2VM.sh $cpuModuleSele($i) | tee /home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out &\r"
			sleep 180
			send "/r"

			#Now find L2 guest IP addr:
			spawn ssh root@$L1GuestIP
			SSH "redhat"
			#SSH "kvmautotest"
			
			#set the timeout is 30 second. if script can not find the L2 guest IP, this timeout can make sure the scripts continue running. 
			set timeout 30

			#find L2 guest IP address:
			send "nmap -sP $L1GuestIP/22|grep -i 52:54:69:B5:35:25 -B 2|head -n 1|sed 's/.*(//g'|sed 's/)//g' \r"
			expect -re ".*\r\n(.*)\r\n\u001b]0;.*"
			set L2GuestIP "$expect_out(1,string)"

			if { $L2GuestIP == $L1GuestIP || $L2GuestIP == "null" } {
				#The L2 guest IP is not found, There must be some thing wrong. 
				puts "***$cpuModuleSele($i) FAIL***,*** please check the file </home/nested-autoshell/cpu-Module/log/boot-intelVM-$cpuModuleSele($i)-Log.out> in the host***"
				send "echo \" L2 with $cpuModuleSele($i) FAIL ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				send "killall qemu-kvm \r"
				expect "*#*"
				sleep 5 

			} else {
				#The L2 guest IP is found. Now login into the L2 guest and execute lscpu:
				spawn ssh root@$L2GuestIP
				SSH "redhat"
				#SSH "kvmautotest"
				send "lscpu\r"
				expect "*#*"
				sleep 10
				send "poweroff \r"
				sleep 10
				expect "*#*"
				puts "$cpuModuleSele($i)  PASS"

				spawn ssh root@$L1GuestIP
				SSH "redhat"
				#SSH "kvmautotest"

				send "echo \" L2 with $cpuModuleSele($i) PASS ! \" >> /home/nested-autoshell/cpu-Module/log/L2-Result.log \r"
				expect "*#*"
				sleep 5
			}
		}
		spawn scp -r -p root@$L1GuestIP:/home/nested-autoshell/cpu-Module/log/ root@$HostIP:/home/nested-autoshell/case-cpuModule/
		SSH "redhat"
		#SSH "kvmautotest"
		puts "***TEST FINISH****"
		puts "***Please check the result in </home/nested-autoshell/case-cpuModule/log/L2-Result.log> in the host"
		puts "***TEST FINISH****"

	} else {
		puts "The CPU module is wrong, please try again."
	}
}




