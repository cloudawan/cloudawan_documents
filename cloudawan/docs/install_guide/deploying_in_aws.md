# Deploying in AWS

This document is intended to give you a step by step guide to deploy one cluster with all infrastructures within the single data center.

## Prerequirements

1. 3 Ubuntu 14.04 server version instances with at least 2 CPU and 8 GB memory for Kubernetes Master/Node hosts.
2. 2 Ubuntu 14.04 server version instances with at least 1 CPU and 2 GB memory for Glusterfs servers and HAproxy servers.
3. The AWS VPC for the private network where Ubuntu instances are.
4. One AWS EIP for outside world to access.
5. The security group used for the Ubuntu instances. This security group rule should allows all inbound/outbound traffic to/from the AWS VPC. Everything on the AWS VPC in prerequirement 3 is kept inside and can't be accessed from Internet so the network security should be alleviated.
6. Allow the inbound ports used by the running applications to be accessible from the Internet. The port 443 is used by the CloudAwan GUI and needs to be allowed. (For applications run on Kubernetes, the default useable ports for the AWS EIP are ranged from 30000 to 32767.)
7. Go to AWS IAM to create a user credential with privilege policy AmazonEC2FullAccess. The credential is used for HAproxy Master/Master to failover where the EIP and the floating private ip are associated/disassociated dynamically. For more fine-grained, the customized policy could be created with four allowed operations: aws ec2 disassociate-address, aws ec2 associate-address, aws ec2 unassign-private-ip-addresses, and aws ec2 assign-private-ip-addresses.

## Install

In order to expose the public floating ip to the Internet, an AWS EIP is required to use. Besides, due to the AWS network rules, the ip needs to assigned to the instances before being accessible. Therefore, the HAproxy Master/Slave will be changed to Master/Master with the AWS CLI integration to assign/unassign the AWS EIP for public and the floating ip for private. The hot-standby controll is moved to AWS EIP and private ip rather than HAProxy.

### Step 1. Deploy the cluster

1. Use the document [deploying cluster](deploying_cluster.md) to deploy the cluster on AWS

### Step 2. Configure

1. Open the file **hosts_aws_haproxy** to modify.
2. Configure the ip for 3 Kubernetes Master/Node hosts in the section [master_node_host]. Change the ip to the physical ip of the Kubernetes Master/Node hosts.
3. Configure the AWS EIP (aws_eip) in the prerequirement 4 and the private floating ip (haproxy_floating_ip) from any reserved ip from the AWS VPC in the prerequirement 3.
4. Configure the credential (aws_access_key_id and aws_secret_access_key) from the prerequirement 7.
5. Configure the region (default_region) to the AWS region where the cluster is deployed.
6. Configure the ip for 2 HAproxy instancfes in the section [haproxy_host]. Change the  username(ansible_user) and password(both ansible_ssh_pass and ansible_become_pass) to the root user and root password. Change the peer host (peer_host) to the counter part. Change the instance id (aws_instance_id) and network interface id (self_network_interface_id). Change the  peer network interface id (peer_network_interface_id) to the network interface id of the counter part.

### Step 3. Run script

1. Run ./aws_haproxy_install.sh and input the password for root privilege.

## The Ansible configuration file

The following is the configuration file /cloudawan_install/kubernetes1.2/hosts_aws_haproxy in the ansible configuration file format.

```
# Kuberntes Master Host or Node Host. That is, the target servers to route to.
# Notice that the target servers should not be across the regions where the network can't be ignored. In that case, GSLB (AWS Route 53) should be considered.

[master_node_host]
192.168.0.71
192.168.0.72
192.168.0.73

# HAproxy
[haproxy:children]
haproxy_host

[haproxy:vars]
# For outside AWS
aws_eip=52.52.50.33
# For inside AWS
haproxy_floating_ip=192.168.0.150
# AWS IAM aws_access_key_id and aws_secret_access_key should be created separately for security issue. Don't use root credential since the profile is stored on the instances.
# This credential should have at least network privilege to associate/disassociate elasitc ip and private ip
aws_access_key_id=XXXXXXXXXXXXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXXXXXXXXXXXX
# The region where the instances are
default_region=us-west-1

[haproxy_host]
# The peer is the counter part. For the master, the peer is the slave. For the slave, the peer is the master.
192.168.0.74 ansible_user=username ansible_ssh_pass=password ansible_become_pass=password state=MASTER peer_host=192.168.0.75 aws_instance_id=i-aae08aef self_network_interface_id=eni-d5fdf3fd peer_network_interface_id=eni-d6fdf3fe
192.168.0.75 ansible_user=username ansible_ssh_pass=password ansible_become_pass=password state=BACKUP peer_host=192.168.0.74 aws_instance_id=i-abe08aee self_network_interface_id=eni-d6fdf3fe peer_network_interface_id=eni-d5fdf3fd
```

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
        <td>aws_eip</td>
        <td>52.52.50.33</td>
        <td>This floating IP is in the hot-standby mode. It is used by the external requests from the Internet.</td>
    </tr>
    <tr>
        <td>haproxy_floating_ip</td>
        <td>192.168.0.150</td>
        <td>This floating IP is in the hot-standby mode. It is used by the internal Kubernetes Node hosts in the private VPC.</td>
    </tr>
    <tr>
        <td>aws_access_key_id</td>
        <td>XXXXXXXXXXXXXXXXXXXXX</td>
        <td>The credential used to associate/disassociate the AWS EIP and private IP.</td>
    </tr>
    <tr>
        <td>aws_secret_access_key</td>
        <td>XXXXXXXXXXXXXXXXXXXXX</td>
        <td>The credential used to associate/disassociate the AWS EIP and private IP.</td>
    </tr>
    <tr>
        <td>default_region</td>
        <td>us-west-1</td>
        <td>The AWS region where the cluster is deployed to.</td>
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
    <tr>
        <td>peer_host</td>
        <td>192.168.0.75</td>
        <td>The ip of the counter part host.</td>
    </tr>
    <tr>
        <td>aws_instance_id</td>
        <td>i-aae08aef</td>
        <td>The instance id of the host.</td>
    </tr>
    <tr>
        <td>self_network_interface_id</td>
        <td>eni-d5fdf3fd</td>
        <td>The network interface id of the host.</td>
    </tr>
    <tr>
        <td>peer_network_interface_id</td>
        <td>eni-d6fdf3fe</td>
        <td>The network interface id of the counter part host.</td>
    </tr>
</table>

## Uninstall HAproxy 

Run ./aws_haproxy_uninstall.sh with the same configuration file aws_haproxy_install and input the password for root privilege. It will first install ansible and then run the ansible template to uninstall.