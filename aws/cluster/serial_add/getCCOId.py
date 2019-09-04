import subprocess
import json
import os

proc0 = subprocess.Popen(['terraform', 'refresh', '-var', 'cco_id=0', '-var', 'initial_num_nodes=0'])
proc0.wait()
proc1 = subprocess.Popen(['terraform','output','-json'], stdout=subprocess.PIPE)
dic = json.load(proc1.stdout)
privIPList = dic['management_aws_network_interface_private_ips']['value']
for i in range(len(privIPList)):
    if len(privIPList[i]) == 2:
        print("{{\"cco_id\": \"{}\" }}".format(i))
        exit(0)