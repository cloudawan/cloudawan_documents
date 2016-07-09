# Overview

In order to leverage DevOps and Microservice Architecture, we category Microservice components into two type: [applications](#application) and [third-party services](#third-party-service). 

Applications means the components developed by users and frequently changed during the development. They are expected to be under version control for source codes, deployable images, and the running instances in the deployment environment.

On the other hand, the third-party services are not developed by users but just used by users for the common functions, such as databases, messaging, streaming, tools, and services from the external sources. They are relatively fixed and are seldom touched in the deployment. The third-party service could be even not managed or deployed in users' environment but just an endpoint to outside service providers.

Take an ecommerce website as example, it consists of four components: Angularjs as frontend, Spring framework as backend, Cassandra as database, and an external Rest API of Paypal payment system. In this case, Angularjs and Spring framework are belonging to the application category and could be put in the same type of the web server component or separated into two types of web server components for better SoC (separation of concerns). Cassandra is the third-party service and the deployed instances are not changed during development. (Unless users want new features and upgrade Cassandra to the new version) Finally, Paypal payment system rest api is the third-party service, too, where the real deployment is not in users' environment.

# Application

The application component is the place holding the users' source codes and the generated deployable images are under version control. Each application component is a independent micoservice which could have its own source code language and unique infrastructures. The application component has no dependency on other application components but may rely on the third-party service, such as database.

## How to design

There are several Microservice design guidelines to divide a huge system into multiple micoservices/components.

### Stateless

The application component should be designed to be stateless so each instance of the group for the same component type is interchangeable. The data is better to be delegated to the third-party service component where it could handle stateful data, either permanent storage or memory cache, with clustering techniques. In this way, there is no dependency among instances of the same component type. More instances could produce more work. As a result, the auto-scaling could help use to adjust(increase/decrease) the amount of the running instances dynamically according to the input traffic. Also, any new instance could replace the old instances without worrying about the data synchronization. Therefore, the automation of failover and auto-repair could alleviate the users' burden on the dead instances.

The concept is like the analogy of the cattle and pets in the IT industry. It's not a good idea to give each instance of a specfic job like pets. If one specifc instance crashes, it need to be brought back to make the specific function work in the system. It will be great to be the cattle. All instances share the same feature and could play the exact same role in the system. If one dies, another instance in the group with the same type could take over the task seamless.

### Immutable infrastructure

For each application component, all the required infrastructures, such as drivers, frameworks, libraries, and ...etc, should be wrapped in the image. Each version of source code has its own image independent from other versions. When there is some change in the source code of this component, a new image will be created and the old running instances of this component will remain untoched. After the new image is tested and validated, the image could be used to create new instances to replace the old running instances one by one or be used to deploy to another environment with other components for more thorough test and switch the whole environment online with [blue-green deployment](#blue-green-deployment) after that.

For the mutable part separated from user application to make it immutable, there are two types: the input parameters and the output data. The input parameters are those user want to configure and initailize this component. They could be passed via the environment variable when launching/updating the application component. For auto-repair or auto-scaling, this application component uses the last environment variable configuration to launch the instances. For the output data, they are the computation results, such as the data in database, generated from this application component. This could be delegated to the third-party service so the application component just needs the drivers to send the data and itself could be immutable without holding the mutalbe data.

![Stateful data](/images/architecture/application_how_to_design_immutable_infrastructure.png)

### Separated build

Each application component should have its own source code repository so each commit could be built as an deployable image. In this way, the new version of the existing component or the new component could be independently introduced to the deployment environment without affecting the other versions or other components. This may cause too many revisions to track and maintain since the release version is now at the compoent level rather than the whole product level. To overcome this deficit, the [topology template](#topology-clonetemplate) is used to snapshot the deployment of all components to keep track of the versions and the deploying order.

## Automation from source code to operation

The automation is from source code along the whole procedure to the final delivery and later management and maintainance. Once the source code is commited to the source code repository, such as github, the platform will retrieve source code, run the build script to compile, run the component-based test, and finally build the Docker image to wrap up everything into a single deployable unit. Then, the deployed instances of this component (not all the components in the cluster are upgraded but just the source code affected parts are upgraded) start to replace themselves one by one without interrupting the running service by the mechanism of rolling update. Finally, the released product clsuter consisting of many components is under management and maintainance, such as auto-scale, failover, auto-repair, event, notification, and ...etc., by the platform. The workflow is like the following and is suggested to use for interal deployment, such as the developing environment.

1. Code
2. Build
3. Deploy
4. Operate

For the production environment, two human intervention steps test and release are suggested to add in the workflow with the [blue-gren deployment](#blue-gren-deployment). After the deployment replaces the instances using the upgraded component, the QA could test the whole environment to make sure there is nothing going wrong on the new upgraded part. After validation by QA, the testing environment could switch to the production environment by one click. The workflow is like the following.

1. Code
2. Build
3. Deploy
4. QA Test
5. Release
6. Operate

![Stateful data](/images/architecture/application_from_source_code_to_operation.png)

![Stateful data](/images/architecture/application_management_feature.png)

# Third-party service

The goal of the third-party service is to free users from the management and maintainance of external softwares, tools, and services so they could focus on their own source codes. There are types: the internal cluster and the external access entry. The internal cluster run on the same Kubernetes hosts and consume some resources while the external access etnry is just bridge to external machines or service providers over Internet.

![Stateful data](/images/architecture/third_party_service_type.png)

## Create/Resize/Delete

For the internal cluster, most of the third-party service templates support creating, resizing, and deleting. For the external endpoint, the resizing is not supported since the real deployment is outside of control.

### Create

For the internal cluster, a group of instances and a service/endpoint are created. Depending on different templates, the program will form the cluster in different way. If there is something wrong in the process, it will return the error message and clean all the instances and related date. The procedure is usually like the following.

1. Create a seed instance.
2. Initialize the configuration with the passed environment parameters.
3. Create a service/endpoint for other instances to acess
4. Create a new instance to join the cluster
5. The new instance retrieves the cluster data, such as the seed instances, and try to join.
6. Tracking the new instance log until it succeeds or fails to join the cluster.
7. Repeat step 4~6 until the configured size is reached. 

**To be more secure, the passed parameters could be put in the Kubernetes secret rather than passed as environment parameters.**

For external access entry, one endpoint is created to represent a group of IPs outside of the Kubernetes hosts. This provides a way for instances within Kubernetes to access the external machines or hosts.

**Unlike the endpoint for the internal cluster, the endpint of the external access entry just provides routing to the real sources but has no health check or failover mechanisms.** To make it more robust, there are two choices:

1. Have a SLB in the middle and use the virtual IP instead of the real IPs of the target external sources.
2. Within the container, use Kubernetes Rest API to get all real IPs and implement the client side health check and failover.

### Resize

If the third-party service is a running cluster on the platform but not an external access entry, the third-party service template usually provides the function to have a new instance join or leave the cluster. The procedure is usually like the following.

1. Create a new instance.
2. The new instance retrieves the cluster data, such as the seed instances, and try to join.
3. Tracking the new instance log until it succeeds or fails to join the cluster.

**Important: data status is unknown.** For most databases, the data synchronization or data hand over starts after the new instance successfully joins the cluster. The platform doesn't know whether the data synchronization or data hand over is successfully finished or not. For scaling out, it is not an issue since it just adds more empty space for the cluster to use. However, the failure may cause problems for scaling in where it may decrease the duplicated copies for data synchronization or break the required quorum amount for data hand over. Therefore, the scaling in is not suggested for the third-party service after the data is inserted.

It is also possible to auto scale the third-party service. However, this behavior is strongly discouraged for the stateful third-party service since it is too risky without human intervention. 

### Delete

For external access entry, the bridge is removed but the external service source is not affected. For the internal cluster, the running isntances are stopped and deleted. If the persistent storage is used, the volumes are unmounted but the data on the volume remains untouched.

## Persistent storage

Persistent storage could be used in the stateful third-party service. By default, the Glusterfs is installed on the hosts and integrated into this platform. Users could manage (create/reset/delete) all kinds (disperse, stripe, replicated, and ...etc.) of the volumes on the platform. On the other, based on Kubernetes' client side mounting and external endpoint design, users could select from a variety of persistent storage providers, such as NFS, Glusterfs, Ceph, AWS EBS, GCE persistent disk, Cinder, and ...etc. as their network file system.

The platform provides **dynamic binding between instances and volumes**. That is, for each storage volume, it is binded to one running instance at a time and could be re-binded to another running instance in other hosts if the previous instance dies. In this way, the mapping between computation and storage is separated. Users are no more required to use the same instance for the same storage volume.

![Stateful data](/images/architecture/third_party_service_persistent_storage_dynamic_binding.png)

# Instance

For the running instances, the smallest deployable unit is the Kubernetes pod. The size of the application or the third-party service is the amount of Kubernetes pods controlled by one or more Kubernetes replication controllers. A pod may contains one or more docker containers. When deploying a pod to host, all containers belonging to that pod are deployed to the same host and share the same IP address and port space. They could access each other via localhost and communicate with each other by the standard inter-process communications.

## Location affinity

For geographical-aware network topology, location affinity could limit the region and the zone to deploy the instances. If not selected, the target instances could be deployed to any host. If the specifc region is selected, the target instances are deployed to any host in the zones belonging to the region. If the specifc region and zone is  selected, the target instances are deployed to any host in the zone in the region.

![Stateful data](/images/architecture/application_instance_location_affinity.png)

## Environment variable

Environment variable is designed to pass parameters to initialize the instances. The values are saved in the replication controller template. Therefore, all launched instances from the same replication controller template share the same values when deploying the application or the third-party servie, scaling out for more running instances, and auto-repairing to replace the dead instance. 

# Service

The service is the Kubernetes service provideing an access entry to the application or the third-party service. Each services has one or more ports routing, either round-robin or sesssion affinity, to the instances of the application or the third-party service. Although the service has cluster ip, that is the internal virtual ip, it is suggested to use domain name to access the service. The domain name is in the format **service.namespace.svc.cluster.local** where service is the service name, namespace is the namespace where the service is in, and cluster.local is the cluster name configured during install. The node port could be configured for the service to be accessed from outside of the Kubernetes hosts.

![Stateful data](/images/architecture/service.png)

# Blue-green deployment

Generally, the blue-green deployment is a method for releasing the product in a predictable manner with an goal of reducing any downtime related to the release. It’s a quick switch to route the traffic from the current serving environment to another environment ready to release and also quickly rollback to the previous working environment if something goes wrong in the new environment. 

The blue-green deployment is to have two identical environment of everything. One environment is the live production environment serving incoming requests while the other is used for new release. After being tested and validated, the traffic is switched from the current environment to another ready environment. If there is a failure in the new environment, it could be rollback soon since the whole working cluster is still in the previous environment

**Stateful data migrations may need to be taken into consideration.** If there are traditional RDBMS, NoSQL, and file-system-based softwares in the environment, the migration plan is required case by case. Take Cassandra cluster as an example, users should set up a time line to get a snapshot of all data before the time line to restore in the new set and configure the database to send the same amount of the data copies to another set so the incoming data won't be lost. Another solution is to let two sets share the same stateful data storage. However, the schema changes may require extra data processing since the data need to be accepted in two different schemas. Besides, during the testing, the extra dummy data should be used so the real data is not messed up.

![Stateful data](/images/architecture/blue_green_deployment_stateful_data.png)

**Note: only the entry component needs to be configured with the blue-green deployment.** All other components behind the entry component are switched automatically since the switched entry component uses the components in the switched namespace .

![Access entry](/images/architecture/blue_green_deployment_access_entry.png)

# Topology clone/template

Users could clone the whole topology from one namespace to another namespace or make it a template for later deployment. However, the data in the running stateful compoents, such as data in database, are not duplicated. **Do not use this to backup the deployments.** The template only contains the information, such as the image version, the environment variables, and the deploying order of, used to deploy and initailize all the compoents. This is designed for the version control of the product level (all components).
