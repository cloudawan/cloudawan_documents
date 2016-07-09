# Installing a single host deployment

## Purpose of the document

This document is intended to give you a step by step guide to quick setup a single host with all infrastructures for quick glimpse. However, some advanced features are restricted with this deployment.

If you would like a detailed walkthrough with instructions for installing clusters, deploying on public cloud, or using hybrid cloud. Please contact us: info@cloudawan.com

## Prerequirements

1. Oracle virtual Box (Linux/Windows/Mac)
2. Spared 4 CPU core and 8 GB memory

## Install the pre-built VirtualBox Template

### Step 1 Download

1. Download the vitrual box template from [Link](https://mega.nz/#!DdNDBIxJ!VVq6ThGpKMwi4_ZnQlNL1HfwNfDJUfflGpDupSrXcoA)

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

Host credentials are required to access the host to issue commands, such as accessing the container shell on GUI, deleting the unused Docker images on host, and ...etc. Due to Docker command requirements, this user used in the credentials needs to have the root privilege or the equivalent privilege group.

1. Go to System -> Host Credential
2. Press "Create" button
3. The field IP is the ip of this host (the one configured in /etc/hosts). The field user is the Linux user with root privilege, that is cloudawan in the case. The field password is the password for the Linux user, that is cloudawan in the case.

### Step 6 (Optional) Configure the GlusterFS server

Configure the Glusterfs server to manage volumes on GUI. Due to Glusterfs command requirements, the user used in the configuration needs to have the root privilege or the equivalent privilege group.

1. Go to FileSystem -> GlusterFS
2. Press "Create" button
3. The file name is a label for user to recognize. Host list is the ip list of GlusterFS servers, that is the ip of this host (the one configured in /etc/hosts) in the case. The field path is the root directory to place the data, that is /data/glusterfs in the case. The field user is the Linux user with root privilege, that is cloudawan in the case. The field password is the password for the Linux user, that is cloudawan in the case.

# Deploying the whole clusters

## Purpose of the document

This document is intended to give you a step by step guide to deploy one cluster with all infrastructures within the single data center.

## Prerequirements

1. 3 Ubuntu 14.04 instances with at least 2 CPU and 8 GB memory for Kubernetes Master/Node hosts
2. 2 Ubuntu 14.04 instances with at least 1 CPU and 2 GB memory for Glusterfs servers
3. The Ubuntu instances could be on AWS, GCE, Virtual Machine environment, bare metal environment and ...etc.

## Install with the ansible

### Step 1 Download

1. Login one of the Ubuntu 14.04 instance
2. Install git with "sudo apt-get install git"
3. Clone from github with "git clone https://github.com/cloudawan/cloudawan_install.git"
4. Move to the directory ./cloudawan_install/kubernetes1.2/

### Step 2 Configuration

1. Open the file **hosts** to modify.
2. Configure the ip for 3 Kubernetes Master/Node hosts in the section [master_node_host]. Change the ip to the physical ip of the Ubuntu 14.04 instance with at least 2 CPU and 8 GB memory and username(ansible_user) and password(both ansible_ssh_pass and ansible_become_pass) to the root user and root password.
3. Configure the host used to configure cluster level install in the section [master_node_host]. Pick up one of the 3 hosts in the section [master_node_host] and put here.
4. Configure the ip for 2 Glusterfs servers in the section [glusterfs_host]. Change the ip to the physical ip of the Ubuntu 14.04 instance with at least 1 CPU and 2 GB memory and username(ansible_user) and password(both ansible_ssh_pass and ansible_become_pass) to the root user and root password.
5. Configure the host used to issue commands to the Glusterfs cluster in the section [glusterfs_configuring]. Pick up one of the 2 hosts in the section [glusterfs_host] and put here.
6. Select the glusterfs seed server for joining in the section [glusterfs:vars]. Change the ip of the parameter seed_host to any one of glusterfs hosts in the section [glusterfs_host].
7. Select the glusterfs hosts to store the disk volumes of the private-registry data and the cloudawan data in the section [glusterfs:vars]. Change the ip of the parameter software_replica_host_1 and software_replica_host_2 to any 2 of glusterfs hosts in the section [glusterfs_host].
8. (Optional) Change the flannel virtual network (flannel_subnet and flannel_subnet_mask_bit) used only internal on the Kubernetes hosts in the section [master_node:vars]. The docker containers will use this network to communicate.
9. (Optional) Change the Kubernetes service network (service_cluster_ip_range) used only insides the docker containers to access Kubernetes service and kubernetes internal dns (service_cluster_dns_ip) used only insides the docker containers for domain name in the section [master_node:vars]. The service_cluster_dns_ip must reside in the service_cluster_ip_range.
10. (Optional) Change the data center label (node_label) in the section [master_node:vars]. The label could be used to do geographical topology awareness when deploying new instances. One region contains many zones and one zones contains many hosts. The network delay between two zones in the same region should be small enough (1~2 ms) to ignore.

### Step 3 Run script

1. Run ./install.sh and input the password for root privilege. It will first install ansible and then run the ansible template to install.
2. The whole process may takes half an hour depending on the network speed since most of big  files are retrieved from the docker hub.