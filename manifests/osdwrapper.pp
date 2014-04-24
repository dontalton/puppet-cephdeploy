#   Copyright 2013-2014 Cisco Systems, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#   Author: Donald Talton <dotalton@cisco.com>

# === Parameters:
# [*disks*]
#   (required) The array of disks to use as OSD.
#     Not set here, but in data/hiera_data/hostname/YOURHOST
#
# [*setup_pools*]
#   (optional) Create the cinder and glance rbd pools.
#
# [*use_kernel_rbd*]
#   (optional) Use kernel rbd driver. Will asume directory as storage if false
#
# [*ceph_deploy_user*]
#   (required) The cephdeploy account username
#
# [*ceph_primary_mon*]
#   (required) The primary MON in the monmap.
#
# [*ceph_cluster_interface*]
#   (required) The name of the network interface clients use to connect to Ceph nodes.
#
# [*ceph_cluster_network*]
#   (required) The network clients use to connect to Ceph nodes.
#
# [*glance_ceph_pool*]
#   (optional) The name of the glance rbd pool.
#
# [*cinder_rbd_pool*]
#   (optional) The name of the cinder rbd pool.
#


class cephdeploy::osdwrapper(
  $disks,
  $setup_pools = true,
  $use_kernel_rbd = false,
  $ceph_deploy_user,
  $ceph_primary_mon,
  $ceph_cluster_interface,
  $ceph_cluster_network,
  $glance_ceph_pool,
  $cinder_rbd_pool,
){

  cephdeploy::osd { $disks:
    setup_pools            => $setup_pools,
    use_kernel_rbd         => $use_kernel_rbd,
    ceph_deploy_user       => $ceph_deploy_user,
    ceph_primary_mon       => $ceph_primary_mon,
    ceph_cluster_interface => $ceph_cluster_interface,
    ceph_cluster_network   => $ceph_cluster_network,
    glance_ceph_pool       => $glance_ceph_pool,
    cinder_rbd_pool        => $cinder_rbd_pool,
  }

}
