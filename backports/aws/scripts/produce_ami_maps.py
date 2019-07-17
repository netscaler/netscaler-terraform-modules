import boto3
import json
import argparse
import os.path
from collections import OrderedDict


# Do the 12.0-62.9 first
generator_list = []


# 12.0-61.9

generator_list.append({
    'filename': 'citrix_adc_vpx_customer_licensed_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-06ae528dc35730099',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_10Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-06274c40f24113232',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_10Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-001bb9492e090208f',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_200Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-009025b3b4b66b6f6',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_express_20Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-0b482f2fbe9556e78',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_10Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-058270c88330d4c08',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_200Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-066e10f436a021af9',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_200Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-02d854b050d6fa5f3',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_1000Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-03a57557342b86960',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_1000Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-0287248bc343b049a',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_1000Mbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-08f38c95bdc7f1d5e',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_5Gbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-0cb457bc20529db4d',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_3Gbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-0b856a499086b2665',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_5Gbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-0645ed6f045864b6e',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_5Gbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-0754ce1d4387d521e',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_3Gbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-0f34eb17303f74e39',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_3Gbps_12.0-61.9.tfvars.json',
    'us-east-1-ami-id': 'ami-09d766381d487b0e4',
})





# 12.1-51.20

generator_list.append({
    'filename': 'citrix_adc_vpx_customer_licensed_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-035cec069e7c0b4e4',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_10Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-097e9ab4cc9b4228c',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_10Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-020324271ff9ac26f',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_200Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-0e9211f8c9cda1ff7',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_express_20Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-021d54e00907f90cd',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_10Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-0d5d9968786b571e8',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_200Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-068e926de46122f5d',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_200Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-08006c66d63065bb0',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_1000Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-05f4ffc7f0818bc4b',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_1000Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-0043ae171a5fc6434',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_1000Mbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-00df6ce3ed189b30f',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_5Gbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-0786ebc7142e687dd',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_3Gbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-03765ad2b2dae8441',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_5Gbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-0b5ff0b5876dc1b62',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_5Gbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-0f991e26f44d692b1',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_3Gbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-0020bcffeb788b01e',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_3Gbps_12.1-51.20.tfvars.json',
    'us-east-1-ami-id': 'ami-026259ffdab87433d',
})



aws_region_names = []

client = boto3.client('ec2')

aws_region_result = client.describe_regions()

for item in aws_region_result['Regions']:
    aws_region_names.append(item['RegionName'])

print(json.dumps(aws_region_names, indent=4))

parser = argparse.ArgumentParser()
parser.add_argument('--output-dir', required=True)

args = parser.parse_args()


def update_dict_for_region(region_name, output_dict):
        print('Inquiring region %s' % region_name)
        c = boto3.client('ec2', region_name=region_name)
        filters = [
            {
                'Name': 'name',
                'Values': [name]
            }
        ]
        description  = c.describe_images(Filters=filters)
        if len(description['Images']) > 1:
            raise Exception('Region %s has multiple images for %s' % (region_name, item['filename']))

        if len(description['Images']) == 0:
            print('Region %s has no image for %s' % (region_name, item['filename']))
        else:
            output_dict[region_name] = description['Images'][0]['ImageId']

def dump_region_dict(region_dict, filename, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    od = OrderedDict()
    for key in sorted(list(region_dict.keys())):
        od[key] = region_dict[key]

    output = {'vpx_ami_map': od}

    output_path = os.path.join(output_dir, filename)
    if os.path.exists(output_path):
        raise Exception('Cannot overwrite %s' % output_path)
    with open(output_path, 'w') as fh:
        json.dump(output, fh, indent=4)


for item in generator_list:
    output_dict = {}
    c = boto3.client('ec2', region_name='us-east-1')
    images = c.describe_images(Filters=[{'Name':'image-id','Values':[item['us-east-1-ami-id']]}])
    if len(images['Images']) > 1:
        raise Exception('More than one image in us-east-1')
    if len(images['Images']) == 0:
        raise Exception('us-east-1 does not contain the ami %s' % item['us-east-1-ami-id'])
    name = images['Images'][0]['Name']
    for region_name in aws_region_names:
        update_dict_for_region(region_name, output_dict)

    dump_region_dict(output_dict, item['filename'], args.output_dir)
