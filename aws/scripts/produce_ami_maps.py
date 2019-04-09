import boto3
import json
import argparse
import os.path
from collections import OrderedDict

generator_list = []

generator_list.append({
    'filename': 'citrix_adc_vpx_customer_licensed_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0fe34330ab860f7f6',
})


generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_10Mbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0635b111d6c6884e2',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_10Mbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0afc262f5eac35b7b',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_200Mbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-035cf6e34ff11c086',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_200Mbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-05bcff04a7ce8167c',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_1000Mbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0dce33ba94490d83f',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_10Mbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0d7e176b61cb877f0',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_200Mbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0faa44954f3b13064',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_1000Mbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-00451060dcaa8f49c',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_1000Mbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-018066ea8b20ddb3c',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_express_20Mbps_12.1-49.27.tfvars.json',
    'us-east-1-ami-id': 'ami-06840c214b8adbd77',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_5Gbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0044fb813dfe2b0af',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_3Gbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0184ed41e2fe7503a',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_3Gbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0eeb2cd33f6a98b52',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_enterprise_edition_3Gbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0b3918c778e5e3759',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_standard_edition_5Gbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-0280ce3c3eef17f5c',
})

generator_list.append({
    'filename': 'citrix_adc_vpx_platinum_edition_5Gbps_12.1-50.28.tfvars.json',
    'us-east-1-ami-id': 'ami-02e0f2f2759ae051b',
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
