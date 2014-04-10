Automating ceph-deploy
======================

This puppet module allows you to fully automate the deployment of a ceph cluster. The need for this sort of functionality came about with the goal of full bottom-up automation of an OpenStack cloud that is ceph-backed.

This module will also configure OpenStack cinder and nova-compute nodes to use the ceph cluster.

*This automation will be implemented in the Havana release of [Cisco OpenStack Installer](http://docwiki.cisco.com/wiki/OpenStack:Grizzly-Multinode)*

Questions? Comments?
Donald Talton
dotalton@cisco.com

* KNOWN BUG *
ceph and mongodb do not seem to co-habitate well due to differences in google-libperftools (0 vs 4 for mongo).


* for this installation, use either the puppet2 or puppet3 versions depending on your puppet version


site.pp variables
-----------------

    $ceph_monitor_fsid = 'e80afa94-a64c-486c-9e34-d55e85f26406'
    $ceph_monitor_secret = 'AQAJzNxR+PNRIRAA7yUp9hJJdWZ3PVz242Xjiw=='
    $cinder_rbd_user = 'admin'
    $cinder_rbd_pool = 'volumes'
    $cinder_rbd_secret_uuid = 'e80afa94-a64c-486c-9e34-d55e85f26406'
    $mon_initial_members = 'control-server'
    $ceph_primary_mon = 'control-server'
    $ceph_monitor_address = '10.0.0.1,' yes leave the trailing comma intact for now
    $ceph_deploy_user = 'k9de9kdkasdok'
    $ceph_deploy_password = 'dsaadsadasdk09as09kdsad'
    $ceph_cluster_interface = 'eth1'
    $ceph_public_interface = 'eth1'
    $ceph_public_network = '10.0.0.0/24'
    $ceph_cluster_network = '10.0.0.0/24'


Installation on your nodes
--------------------------

This is the base class that installs ceph and configures the requirements on the system. If you are using this on a nova-compute node, you must pass "has_compute".


Install
-------
    class {'cephdeploy':
      ceph_deploy_user     => "$::ceph_deploy_user",
      ceph_deploy_password => "$::ceph_deploy_password",
      ceph_monitor_fsid    => "$::ceph_monitor_fsid",
      mon_initial_members  => "$::mon_initial_members",
      ceph_monitor_address => "$::ceph_monitor_address",
      ceph_public_network  => "$::ceph_public_network",
      ceph_cluster_network => "$::ceph_cluster_network",
      has_compute          => false,
    }


    # on a compute node
    class {'cephdeploy':
      ceph_deploy_user     => "$::ceph_deploy_user",
      ceph_deploy_password => "$::ceph_deploy_password",
      ceph_monitor_fsid    => "$::ceph_monitor_fsid",
      mon_initial_members  => "$::mon_initial_members",
      ceph_monitor_address => "$::ceph_monitor_address",
      ceph_public_network  => "$::ceph_public_network",
      ceph_cluster_network => "$::ceph_cluster_network",
      has_compute          => true,
    }


Create a MON
------------

    class {'cephdeploy::mon':
      ceph_deploy_user      => "$::ceph_deploy_user",
      ceph_cluster_name     => "$::ceph_cluster_name",
      ceph_primary_mon      => "$::ceph_primary_mon",
      ceph_public_network   => "$::ceph_public_network",
      ceph_public_interface => "$::ceph_public_interface",
    }



Create an OSD
-------------
Multiple disks call for multiple declaration.

    class { 'cephdeploy::osdwrapper':
      disks                  => 'sdb',
      setup_pools            => true,
      ceph_deploy_user       => "$::ceph_deploy_user",
      ceph_primary_mon       => "$::ceph_primary_mon",
      ceph_cluster_interface => "$::ceph_cluster_interface",
      ceph_cluster_network   => "$::ceph_cluster_network",
      glance_ceph_pool       => "$::glance_rbd_pool",
      cinder_rbd_pool        => "$::cinder_rbd_pool",
    }


Create an MDS
-------------
    class {'cephdeploy::mds': }


Create a client-only node
-------------------------

The point of this class is to install ceph and its keys. This class should only be called on a node that is not running, or going to ever run, any additional ceph services. For example, this is what you want to use on a controller that has no mon.

    class {'cephdeploy::baseconfig': }





Using puppet-cephdeploy with the stackforge/openstack-installer (use the stable/oi-aio branch)
===============================================================

Follow the instructions for deploy an AIO node using the puppet_openstack_builder, then:

in data/class_groups create files:
```
ceph_all.yaml
ceph_mon.yaml
ceph_osd.yaml
```

ceph_all:
```
class_groups:
  - ceph_mon
  - ceph_osd
```

ceph_mon.yaml
```
classes:
  - cephdeploy::mon
```

ceph_osd.yaml
```
classes:
  - cephdeploy::osdwrapper
```



In data/hiera_data/hostname add a yaml override file for your OSD host. This is where you specify what disks to use as OSDs. The name of the yaml file should be the short hostname of the host you are configuring the OSDs for.

ceph.yaml:
```
cephdeploy::osdwrapper::disks:
  - sdb
  - sdc
```

Modify the relevent class_group file to call the ceph puppetry on your nodes (eg controller.yaml, compute.yaml)

controller.yaml
```
class_groups:
  - ...
  - ceph_all
```

Add all your ceph configuration variables to data/hiera_data/user.common.yaml

user.common.yaml
```
# ceph config
ceph_cluster_name: 'ceph'
ceph_monitor_fsid: 'e80afa94-a64c-486c-9e34-d55e85f26406'
ceph_monitor_secret: 'AQAJzNxR+PNRIRAA7yUp9hJJdWZ3PVz242Xjiw=='
cinder_rbd_user: 'admin'
cinder_rbd_pool: 'volumes'
glance_ceph_pool: 'images'
cinder_rbd_secret_uuid: 'e80afa94-a64c-486c-9e34-d55e85f26406'
mon_initial_members: 'ceph' #be sure to use the short hostname eg. hostname -s
ceph_primary_mon: 'ceph' #be sure to use the short hostname eg. hostname -s
ceph_monitor_address: '10.0.0.1,' #leave the trailing comma until I fix this issue
ceph_deploy_user: 'cephdeploy'
ceph_deploy_password: '9jfd29k9kd9'
ceph_cluster_interface: 'eth1'
ceph_cluster_network: '10.0.0.0/24'
ceph_public_interface: 'eth1'
ceph_public_network: '10.0.0.0/24'
```


Modify the hiera data for configuring cinder and glance to use RBD as their backends:


in data/global_hiera_params/common.yaml:
```
cinder_backend: rbd
glance_backend: rbd
```


in data/hiera_data/cinder_backend/rbd.yaml:
```
cinder::volume::rbd::rbd_pool: 'volumes'
cinder::volume::rbd::glance_api_version: '2'
cinder::volume::rbd::rbd_user: 'admin'
# keep this the same as your ceph_monitor_fsid âcinder::volume::rbd::rbd_secret_uuid: 'e80afa94-a64c-486c-9e34-d55e85f26406'
```

in data/hiera_data/glance_backend/rbd.yaml:
```
glance::backend::rbd::rbd_store_user: 'admin'
glance::backend::rbd::rbd_store_ceph_conf: '/etc/ceph/ceph.conf'
glance::backend::rbd::rbd_store_pool: 'images'
glance::backend::rbd::rbd_store_chunk_size: '8'
```



