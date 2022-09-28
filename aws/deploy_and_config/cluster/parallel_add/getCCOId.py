import subprocess
import json
import os

proc0 = subprocess.Popen(['terraform', 'refresh', '-var', 'cco_id=0', '-var', 'initial_num_nodes=0'])
proc0.wait()
proc1 = subprocess.Popen(['terraform','output','-json'], stdout=subprocess.PIPE)
proc1.wait()
dic = json.load(proc1.stdout)
total_nodes = len(dic['management_aws_netowrk_interface_private_ip']['value'])
privIPList = dic['management_aws_network_interface_private_ips']['value']
for i in range(len(privIPList)):
    if len(privIPList[i]) == 2:
        print("{{\"current_number_of_nodes\": \"{}\", \"cco_id\": \"{}\" }}".format(total_nodes ,i))
        break
else:
    print("{{\"current_number_of_nodes\": \"{}\"}}".format(total_nodes))