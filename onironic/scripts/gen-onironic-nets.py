#!/usr/bin/python

import os
import sys
import random
import socket
import argparse


def cidr(prefix):
    return socket.inet_ntoa(struct.pack(">I", (0xffffffff << (32 - prefix)) & 0xffffffff))

def get_vxlan():
    # Get a random number between 1 and 16M for a starting vxlan num
    # Was using the ssh key initially, but this may change as new servers are added per project.
    # Changed to initial random that will be used for the duration of the project as it will be
    # recorded in the vars config on the deploy server.
    ranret = random.randrange(10001, 16000000)
    return ranret

def save_config(outfile, config, force):

    # We don't want to loose our original values, so only write if the file does NOT exist
    if os.path.isfile(outfile) and not force:
        print("{} already exists.  If you really want to overwrite this file, use the --force argument")
        sys.exit(255)
    else:
        # write to the confing file
        fd = open(outfile, "w")
        fd.write(config)
        fd.close()
    

def main():

    # Parse any provided arguments
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--outfile", required=True, help="File to dump output to")
    ap.add_argument("-s", "--step", required=False, default=16, help="Step for vxlan assignment.. vxlan+step, vxlan+(step*2)...  sloud1 onmetal uses a /20(16 step)")
    ap.add_argument("-p", "--prefix", required=False, default="172.22", help="Prefix to use for the vxlan networks. Default is 172.22.")
    ap.add_argument("-f", "--force", dest='force', action='store_true', help="Force overwrite of existing config")
    args = vars(ap.parse_args())

    # Set some vars
    step = args['step']
    prefix = args['prefix']
    outfile = args['outfile']
    force = args['force']
    config = ""

    # Pull the vxlan to use as a base 
    vxlan = get_vxlan()
    #print "vxlan: {}".format(vxlan)

    # Set the vxlan group based off of the vxlan
    vxlan_group_loct = vxlan % 254
    vxlan_group =  "239.51.50.{}".format(vxlan_group_loct)
    config = config + "vxlan_group: {}\n\n".format(vxlan_group)

    # Parse through each network and create 
    curvxlan = vxlan
    count = 0
    for osnet in ['mgmt', 'storage', 'flat', 'vlan', 'tunnel', 'repl']:

         config = config + "{}_vxlan: {}\n".format(osnet, curvxlan)
         config = config + "{}_network: {}.{}.0/20\n".format(osnet, prefix, count)
         config = config + "{}_netmask: 255.255.240.0\n\n".format(osnet, prefix, count)

         curvxlan = curvxlan + 1
         count = count + step


    # Save config
    save_config(outfile, config, force)




if __name__ == '__main__':

  main()
