# Installing a single host deployment

## Purpose of the document

This document is intended to give you a step by step guide to quick setup a single host with all infrastructures for quick glimpse. However, some advanced features are restricted with this deployment.

If you would like a detailed walkthrough with instructions for installing clusters, deploying on public cloud, or using hybrid cloud. Please contact us: info@cloudawan.com

## Prerequirements

1.	Oracle virtual Box (Linux/Windows/Mac)
2.	Spared 4 CPU core and 8 GB memory

## Install the pre-built VirtualBox Template

### Step 1 Download

Download the vitrual box template from [Link](https://mega.nz/#!DdNDBIxJ!VVq6ThGpKMwi4_ZnQlNL1HfwNfDJUfflGpDupSrXcoA)

### Step 2 Import

Import the template into the Virtual Box. 

1. From VirtualBox menu select File ­-> Import Appliance.
2. Select the ova image that you downloaded.
3. Click Next button and then Import.

### Step 3 Configure ip

You could use either dhcp or static ip for this instance.

1. Start the VirtualBox instance K8MasterAndNodeDynamicIP.
2. Use cloudawan/cloudawan as username/password to login Linux terminal.
3. Find the ip of the network interface eth0 by the command "ifconfig"
4. Replacing the ip 192.168.0.59 (k8node private-registry) in /etc/hosts with the eth0 ip
5. Reboot the machine with "sudo reboot"

### Step 4 Check for the CloudAwan to come up

1. After reboot, login Linux terminal and use command "kubectl get pod" to check whether the status colume of the pod having the prefix cloudone-all is "Running".
2. Enter url ​https://{eth0 ip}:30003 on the browser with admin/password as usernmae/password
3. Go to Dashboard -> HealthCheck to see wether all components are running. Each component is independent and has different time cost to initialize.

### Step 5 Configure host credentials

Host credentials are required to access the host to issue commands, such as accessing the container shell on GUI, deleting the unused Docker images on host, and ...etc. Due to Docker command requirements, this user used in the credentials needs to have the root priviledge or the equivalent priviledge group.

1. Go to System -> Host Credential
2. Press "Create" button
3. The field IP is the ip of this host (the one configured in /etc/hosts). The field user is the Linux user with root priviledge, that is cloudawan in the case. The field password is the password for the Linux user, that is cloudawan in the case.

### Step 6 (Optional) Configure the GlusterFS server

Configure the Glusterfs server to manage volumes on GUI. Due to Glusterfs command requirements, the user used in the configuration needs to have the root priviledge or the equivalent priviledge group.

1. Go to FileSystem -> GlusterFS
2. Press "Create" button
3. The file name is a label for user to recognize. Host list is the ip list of GlusterFS servers, that is the ip of this host (the one configured in /etc/hosts) in the case. The field path is the root directory to place the data, that is /data/glusterfs in the case. The field user is the Linux user with root priviledge, that is cloudawan in the case. The field password is the password for the Linux user, that is cloudawan in the case.