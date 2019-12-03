#!/usr/bin/python3

import os
#from virttest import SSH
#from virttest import vm

KVM_CPUMod = ["Conron", 
              "Nehalem", 
              "Penryn",
              "Westmere", 
              "SandyBridge", 
              "cpu64-rhel6", 
              "IvvBridge", 
              "IvyBridge", 
              "Haswell", 
              "Broadwell", 
              "Skylake-Clinet", 
              "Icelake-Client", 
              "n270"]

input_CPU = input("Enter the CPU Module:" )

def start_vm():
    #virttest.vm
    pass

def loggin_vm():
    #virttest.SSH(L1_IP)
    pass

def setup_virt_env():
    #os.system("./setup_kvm_env")
    #os.system("./Install_Avocado")
    pass

def choice_L2_CPUMod():
    _index = KVM_CPUMod.index(input_CPU)
    print ("the CPU type is:")

    for L2_CPUMod in KVM_CPUMod[_index:]:
        print (L2_CPUMod)
        
        def start_L2vm():
            #virttest.vm(L2_CPUMod)
            pass

        def loggin_L2vm():
            #virttest.SSH
            pass

        def verify_cpuMod():
            #os.system("lscpu")
            #if output == L2_CPUMod
                #print("PASS")

            #else:
                #print("Fall")
            pass

print (choice_L2_CPUMod())
