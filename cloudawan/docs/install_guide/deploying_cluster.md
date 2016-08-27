# Deploying the whole cluster

This document is intended to give you a step by step guide to deploy the initial cluster with all infrastructures within the single data center. It contains Kubernetes Master hosts, Kubernetes Node hosts, Glusterfs servers, and HAProxy servers.

## Prerequirements

1. 3 Ubuntu 14.04 server version instances with at least 2 CPU and 8 GB memory for Kubernetes Master/Node hosts.
2. 2 Ubuntu 14.04 server version instances with at least 1 CPU and 2 GB memory for Glusterfs servers and HAproxy servers.
3. The Ubuntu instances could be run on AWS, GCE, Virtual Machine environment, bare metal environment and ...etc.

## Topology

### Functional view

![Stateful data](/images/install_guide/deploying_cluster_functional_view.png)

### Host View

![Stateful data](/images/install_guide/deploying_cluster_host_view.png)

## Install

### Step 1. Download

1. Login one of the Ubuntu 14.04 instances.
2. Install git with "sudo apt-get install git".
3. Clone from github with "git clone https://github.com/cloudawan/cloudawan_install.git".
4. Move to the directory "./cloudawan_install/kubernetes1.2/".

### Step 2. Configure

1. Open the file **hosts_cluster** to modify.
2. Configure the ip for 3 Kubernetes Master/Node hosts in the section [master_node_host]. Change the ip to the physical ip of the Ubuntu 14.04 instance with at least 2 CPU and 8 GB memory and username(ansible_user) and password(both ansible_ssh_pass and ansible_become_pass) to the root user and root password.
3. Configure the ip for 2 Glusterfs servers in the section [glusterfs_host]. Change the ip to the physical ip of the Ubuntu 14.04 instance with at least 1 CPU and 2 GB memory and username(ansible_user) and password(both ansible_ssh_pass and ansible_become_pass) to the root user and root password.
4. Configure the master host slb vip in the section [glusterfs:vars] to the floating ip of HAProxy(haproxy_floating_ip in section [haproxy:vars]). Hosts will use this floating ip supported by HA to communicate with master host cluster.
5. Configure the ip for 2 HAproxy servers in the section [haproxy_host]. Change the ip to the physical ip of the Ubuntu 14.04 instance with at least 1 CPU and 2 GB memory and username(ansible_user) and password(both ansible_ssh_pass and ansible_become_pass) to the root user and root password.
6. Configure the floating IP (haproxy_floating_ip in section [haproxy:vars]) to an IP reserved in the same physical subnet. The floating ip is in the hot-standby mode. If the active HAproxy server is down, the other will take over this floating ip immediately. This ip should not be used by any other machine in the subnet.
7. Configure the domain name suffix (domain_name_suffix in section [haproxy:vars]) to the suffix of all services exported to Internet. This is used to provide domain name service access to the Kubernetes services of the deployed applications. The access entry will be application_name.service_name.domain_name_suffix:container_port. Also, users should configure the *.domain_name_suffix to send to the floating IP (haproxy_floating_ip in section [haproxy:vars]) in the public domain service providers.
8. (Optional) Change the flannel virtual network (flannel_subnet and flannel_subnet_mask_bit) used only internal on the Kubernetes hosts in the section [master_node:vars]. The docker containers will use this network to communicate.
9. (Optional) Change the Kubernetes service network (service_cluster_ip_range) used only insides the docker containers to access Kubernetes service and kubernetes internal dns (service_cluster_dns_ip) used only insides the docker containers for domain name in the section [master_node:vars]. The service_cluster_dns_ip must reside in the service_cluster_ip_range.
10. (Optional) Change the data center label (node_label) in the section [master_node:vars]. The label could be used to do geographical topology awareness when deploying new instances. One region contains many zones and one zones contains many hosts. The network delay between two zones in the same region should be small enough (1~2 ms) to ignore.

### Step 3. Run script

1. Run ./cluster_install.sh and input the password for root privilege. It will first install ansible and then run the ansible template to install.
2. The whole process may takes half an hour depending on the network speed since most of big  files are retrieved from the docker hub.

## The Ansible configuration file

The following is the configuration file /cloudawan_install/kubernetes1.2/hosts_cluster in the ansible configuration file format.

```
# Kubernetes Master role or Node role hosts
[master_node:children]
master_node_host

[master_node:vars]
# The virtual network used for containers to communicate
flannel_subnet=172.16.0.0
flannel_subnet_mask_bit=16
# The virtual network used for the Kubernetes services. This should be the subset of flannel_subnet.
service_cluster_ip_range=172.17.3.0/24
service_cluster_dns_ip=172.17.3.10
# This is used to provide location awareness. The difference between region and zone is that the network delay between zones is small enough to ignore while it is not between regions.
node_label="region=region1,zone=zone1"
# Restrict the location to deploy
private_registry_region="region1"
private_registry_zone="zone1"
cloudone_all_region="region1"
cloudone_all_zone="zone1"
# Generate certificates for Kubernetes components to use bi-directional SSL to secure the communication.
# User could use their own CA certificates to sign the generated certificates. 
# The file path could be relative or absolute. If not indicated, one CA pair will be generated.
# The generated CA pair should keep safely and will be used when adding new Kubernetes Node hosts.
certificate_ca_certificate_file_path=""
certificate_ca_key_file_path=""
certificate_ca_key_passphrase="password"
certificate_ca_valid_days=36500
certificate_server_valid_days=36500

# Install infrastructure
[master_node_host]
192.168.0.71 ansible_user=username ansible_ssh_pass=password ansible_become_pass=password
192.168.0.72 ansible_user=username ansible_ssh_pass=password ansible_become_pass=password
192.168.0.73 ansible_user=username ansible_ssh_pass=password ansible_become_pass=password



# Glusterfs
[glusterfs:children]
glusterfs_host

[glusterfs:vars]
# This is the ip used to connect to Kubernetes master hosts.
master_host_slb_vip=192.168.0.150

[glusterfs_host]
# At least two hosts are required due to the HA configuration. 
# The first host {{ groups['glusterfs_host'][0] }} will be used as the seed host.
# The first host {{ groups['glusterfs_host'][0] }} and the second host {{ groups['glusterfs_host'][1] }} will hold the volumes for system programs
192.168.0.74 ansible_user=username ansible_ssh_pass=password ansible_become_pass=password
192.168.0.75 ansible_user=username ansible_ssh_pass=password ansible_become_pass=password



# HAproxy
[haproxy:children]
haproxy_host

[haproxy:vars]
# This floating ip is in the hot-standby mode. If the active HAProxy server is down, the other will take over.
# This is also the ip used to connect to Kubernetes master hosts. That is the role of master_host_slb_vip.
haproxy_floating_ip=192.168.0.150
# Domain name suffix. This is used to provide domain name service access to the Kubernetes services of the deployed applications. The access entry will be application_name.service_name.domain_name_suffix:container_port
domain_name_suffix=cloudawan.com

[haproxy_host]
192.168.0.74 ansible_user=username ansible_ssh_pass=password ansible_become_pass=password
192.168.0.75 ansible_user=username ansible_ssh_pass=password ansible_become_pass=password
```

### Kubernetes

#### Shared Variable [master_node:vars]

These parameters are shared by all Kubernetes Master hosts and Kubernetes Node hosts.

<table>
    <tr>
        <td>Variable Name</td>
        <td>Example</td>
        <td>Description</td>
    </tr>
    <tr>
        <td>flannel_subnet</td>
        <td>172.16.0.0</td>
        <td>The virtual network used within Kubernetes hosts for Docker containers to communicate. It is a flat network provided by Flannel.</td>
    </tr>
    <tr>
        <td>flannel_subnet_mask_bit</td>
        <td>16</td>
        <td>The range of the Flannel virtual network</td>
    </tr>
    <tr>
        <td>service_cluster_ip_range</td>
        <td>172.17.3.0/24</td>
        <td>The virtual network used by Kubernetes kube-proxy to provide access for  Kubernetes services. It should not overlap with the Flannel virtual network.</td>
    </tr>
    <tr>
        <td>service_cluster_dns_ip</td>
        <td>172.17.3.10</td>
        <td>The virtual ip of the Kubernetes dns service. All containers could ask the service ip with the Kubernetes service domain name in the Kubernetes format (service_name).(namespace_name).svc.(cluster).(local)</td>
    </tr>
    <tr>
        <td>node_label</td>
        <td>"region=region1,zone=zone1"</td>
        <td>The Kubernetes node host label for all Node hosts in the initial cluster. It is usd to identify different data center in different regions and different zones.</td>
    </tr>
    <tr>
        <td>private_registry_zone</td>
        <td>"zone1"</td>
        <td>The zone the private-registry is limited to hold.</td>
    </tr>
    <tr>
        <td>private_registry_region</td>
        <td>"region1"</td>
        <td>The region the private-registry is limited to hold.</td>
    </tr>
	<tr>
        <td>cloudone_all_region</td>
        <td>"region1"</td>
        <td>The region the cloudone, that is the management platform, is limited to hold.</td>
    </tr>
    <tr>
        <td>cloudone_all_zone</td>
        <td>"zone1"</td>
        <td>The zone the cloudone, that is the management platform, is limited to hold.</td>
    </tr>
	<tr>
        <td>certificate_ca_certificate_file_path</td>
        <td></td>
        <td>The file path of the ca certificate used to verify the generated certificates for hosts. The file path could be relative or absolute. If not indicated, one CA pair will be generated.</td>
    </tr>
	<tr>
        <td>certificate_ca_key_file_path</td>
        <td></td>
        <td>The file path of the ca key used to sign the generated certificates for hosts. The file path could be relative or absolute. If not indicated, one CA pair will be generated.</td>
    </tr>
	<tr>
        <td>certificate_ca_key_passphrase</td>
        <td>"password"</td>
        <td>If the file path for ca is empty. This will be used as the password for the generated self-signed CA.</td>
    </tr>
	<tr>
        <td>certificate_ca_valid_days</td>
        <td>36500</td>
        <td>The valid duration for the generated CA.</td>
    </tr>
	<tr>
        <td>certificate_server_valid_days</td>
        <td>36500</td>
        <td>The valid duration for the generated certificates.</td>
    </tr>
</table>

#### Host Variable [master_node_host]

Each host has its own independent variables following the host ip. The hosts here have both Kubernetes Master programs and Node programs so they play two roles. 

<table>
    <tr>
        <td>Variable Name</td>
        <td>Example</td>
        <td>Description</td>
    </tr>
    <tr>
        <td>ansible_user</td>
        <td>username</td>
        <td>The username to login this host. The user must have the root privilege</td>
    </tr>
    <tr>
        <td>ansible_ssh_pass</td>
        <td>password</td>
        <td>The password for the ansible_user.</td>
    </tr>
    <tr>
        <td>ansible_become_pass</td>
        <td>password</td>
        <td>The password for the ansible_user to use sudo. Generally, it is the same as ansible_ssh_pass.</td>
    </tr>
</table>

### Glusterfs

#### Shared Variable [glusterfs:vars]

These parameters are shared by all Glusterfs hosts.

<table>
    <tr>
        <td>Variable Name</td>
        <td>Example</td>
        <td>Description</td>
    </tr>
	<tr>
        <td>master_host_slb_vip</td>
        <td>192.168.0.150</td>
        <td>The virtual IP provided by the SLB to route to the master host. The health check dameon will send the data to the port 4001 of the master_host_slb_vip. If there is no SLB, the master host could be used here but there won't be HA.</td>
    </tr>
</table>

#### Host Variable [glusterfs_host]

Each host has its own independent variables following the host ip. The hosts here have Glusterfs server side programs. 

<table>
    <tr>
        <td>Variable Name</td>
        <td>Example</td>
        <td>Description</td>
    </tr>
    <tr>
        <td>ansible_user</td>
        <td>username</td>
        <td>The username to login this host. The user must have the root privilege</td>
    </tr>
    <tr>
        <td>ansible_ssh_pass</td>
        <td>password</td>
        <td>The password for the ansible_user.</td>
    </tr>
    <tr>
        <td>ansible_become_pass</td>
        <td>password</td>
        <td>The password for the ansible_user to use sudo. Generally, it is the same as ansible_ssh_pass.</td>
    </tr>
</table>

### HAProxy

#### Shared Variable [haproxy:vars]

These parameters are shared by all Glusterfs hosts.

<table>
    <tr>
        <td>Variable Name</td>
        <td>Example</td>
        <td>Description</td>
    </tr>
    <tr>
        <td>haproxy_floating_ip</td>
        <td>192.168.0.150</td>
        <td>This floating IP is in the hot-standby mode. If the active HAProxy server is down, the other will take over. This is also the ip used to connect to Kubernetes master hosts. The health check dameon will send the data to the port 4001 of the haproxy_floating_ip</td>
    </tr>
    <tr>
        <td>domain_name_suffix</td>
        <td>cloudawan.com</td>
        <td>The domain name suffix. This is used to provide domain name service access to the Kubernetes services of the deployed applications. The access entry will be application_name.service_name.domain_name_suffix:container_port</td>
    </tr>
</table>

#### Host Variable [haproxy_host]

Each host has its own independent variables following the host ip. The hosts here have HAProxy programs. 

<table>
    <tr>
        <td>Variable Name</td>
        <td>Example</td>
        <td>Description</td>
    </tr>
    <tr>
        <td>ansible_user</td>
        <td>username</td>
        <td>The username to login this host. The user must have the root privilege</td>
    </tr>
    <tr>
        <td>ansible_ssh_pass</td>
        <td>password</td>
        <td>The password for the ansible_user.</td>
    </tr>
    <tr>
        <td>ansible_become_pass</td>
        <td>password</td>
        <td>The password for the ansible_user to use sudo. Generally, it is the same as ansible_ssh_pass.</td>
    </tr>
</table>


## Uninstall cluster

Run ./cluster_uninstall.sh with the same configuration file hosts_cluster and input the password for root privilege. It will first install ansible and then run the ansible template to uninstall.