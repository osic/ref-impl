OpenStack-ansible VS OpenStack_default configurations (liberty)
=============================

Intro
------

This document presents an inventory of different configurations adopted by OSA unlike defaults which may effect OpenStack performance. We start with configurations common to all projects and we finish with those which are projects-specific settings.

### All projects

some of the configurations encountered are common to all projects and are found in `project`.conf for each project:

* In OSA, all projects that relies on keystoneauth for authentication uses caching and encryption of tokens to avoid cache poisoning.
A snippet is shown below:
```
    [keystone_authtoken]
    token_cache_time = 300
    revocation_cache_time = 60 (default 10)

    # if your memcached server is shared, use these settings to avoid cache poisoning
    memcache_security_strategy = ENCRYPT
    memcache_secret_key = <memcached_encryption_key>
```

* While number of workers to be created to service requests in different OpenStack projects is defaulted to number of CPUs, OSA uses half the number of available CPUs for that. A list of some workers parameters and where to find them is given below:

    **workers** in **(glance-api.conf, glance-registry.conf, nova.conf)**  
    **osapi_volume_workers** in **(cinder.conf)**  
    **osapi_compute_workers** in **(nova.conf)**  
    **metadata_workers** in **(nova.conf)**  
    **num_engine_workers** in **(heat.conf)**



#### Keystone (Keystone.conf)

|    section    |    parameter    |                parameter indication               |       OS default conf      |    Osa configurations   |
|:-------------:|:---------------:|:-------------------------------------------------:|:--------------------------:|:-----------------------:|
|     cache     |     backend     |            cache backend driver to use            | keystone.common.cache.noop | dogpile.cache.memcached |
|     cache     |     enabled     |                    enable cahce                   |            false           |           true          |
|     token     |     provider    |                token format to use                |            uuid            |          fernet         |
| fernet_tokens | max_active_keys | number of keys held in rotation before discarding |              3             |            7            |

#### glance (glance-api.conf)

| section | parameter     |                  parameter meaning                   | OS default conf | Osa configurations                     |
|---------|---------------|------------------------------------------------------|-----------------|----------------------------------------|
| DEFAULT | rpc_backend   |                  rpc driver to use                   |      rabbit     | glance.openstack.common.rpc.impl_kombu |
| DEFAULT | scrub_time    | time in seconds  to delay before performing a delete |          0      |                 43200                  |


#### nova (nova.conf)

| section |           parameter          |                     parameter indication                    | OS default conf | Osa configurations |
|:-------:|:----------------------------:|:-----------------------------------------------------------:|:---------------:|:------------------:|
| DEFAULT |       service_down_time      |       Maximum time since last check-in for up service       |        60       |         120        |
| DEFAULT |     cpu_allocation_ratio     |         Virtual CPU to physical CPU allocation ratio        |       0.0       |         2.0        |
| DEFAULT |     disk_allocation_ratio    |        Virtual disk to Physical disk allocation ratio       |       1.0       |         1.0        |
| DEFAULT |     ram_allocation_ratio     |         Virtual ram to Physical ram allocation ratio        |       0.0       |         1.0        |
| DEFAULT |     ram_weight_multiplier    |              Multiplier used for weighting ram              |       1.0       |         5.0        |
| DEFAULT |     reserved_host_disk_mb    |           Amount of disk in MB to reserve for host          |        0        |        2048        |
| DEFAULT |    reserved_host_memory_mb   |          Amount of memory in MB to reserve for host         |       512       |        2048        |
| DEFAULT | scheduler_driver_task_period |                  periodic tasks rerun time                  |        60       |         60         |
| DEFAULT |  scheduler_host_subset_size  |       Subset of N best hosts to schedule new instances      |        1        |         10         |
| DEFAULT | image_cache_manager_interval |     seconds between two runs of the image cache manager     |       2400      |  0 (default rate)  |
| libvirt |           cpu_mode           | setting to host model will clone the host CPU feature flags |       None      |     host-model     |

#### heat (heat.conf)

| section |   parameter   |                    parameter meaning                 | OS default conf | Osa configurations                   |
|---------|---------------|------------------------------------------------------|-----------------|--------------------------------------|
| DEFAULT |  rpc_backend  |                     rpc driver to use                | rabbit          | heat.openstack.common.rpc.impl_kombu |

