from cluster import CitrixADC
import sys
import json

if len(sys.argv) != 2:
    logger.error('Usage: python3 reset_password.py <file.json>')
    exit()

filename = sys.argv[1]

input_data = json.load(open(filename))
primary_nsips = []
all_nsips = []
all_instIDs = []
for key, value in input_data.items():
    if key == 'management_aws_netowrk_interface_private_ip':
        primary_nsips = value['value']
    elif key == 'management_aws_network_interface_private_ips':
        all_nsips = value['value']
    elif key == 'citrix_adc_aws_intance_id':
        all_instIDs = value['value']

# change the password to 'nsroot'
for n in range(len(primary_nsips)):
    nodeObj = CitrixADC(primary_nsips[n], nspass=all_instIDs[n])
    nodeObj.change_password(new_pass='nsroot')
    nodeObj.save_config()
    nodeObj = None