#!/usr/bin/env python3

import argparse
import shutil
import os
import subprocess

nspreboot_str = '''\
<NS-PRE-BOOT-CONFIG>
    <NS-CONFIG>
        add route 0.0.0.0 0.0.0.0 %s
    </NS-CONFIG>
    <NS-BOOTSTRAP>
        <SKIP-DEFAULT-BOOTSTRAP>YES</SKIP-DEFAULT-BOOTSTRAP>
        <NEW-BOOTSTRAP-SEQUENCE>YES</NEW-BOOTSTRAP-SEQUENCE>

        <MGMT-INTERFACE-CONFIG>
            <INTERFACE-NUM>eth0</INTERFACE-NUM>
            <IP>%s</IP>
            <SUBNET-MASK>%s</SUBNET-MASK>
        </MGMT-INTERFACE-CONFIG>
    </NS-BOOTSTRAP>
</NS-PRE-BOOT-CONFIG>
'''

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--nsip', required=True)
    parser.add_argument('--netmask', default="255.255.255.0")
    parser.add_argument('--gateway', required=True)
    parser.add_argument('--output-dir', default="iso_preboot_config")
    
    args = parser.parse_args()
    output_str = nspreboot_str % (args.gateway, args.nsip, args.netmask)

    # Check if output directory exists
    if os.path.exists(args.output_dir):
        print('Deleting existing output dir %s', args.output_dir)
        shutil.rmtree(args.output_dir)

    os.makedirs(args.output_dir)
    output_file = os.path.join(args.output_dir, 'userdata')
    with open(output_file, 'w') as fh:
        fh.write(output_str)

    # Create iso file
    iso_output_file = '.'.join([args.output_dir,'iso'])
    cp = subprocess.run(['mkisofs', '-o', iso_output_file, args.output_dir])
    cp.check_returncode()


if __name__ == '__main__':
    main()
