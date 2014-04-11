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
#
# [*setup_pools*]
#   (optional) Create the cinder and glance rbd pools.
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


define cephdeploy::osd(
  $setup_pools = true,
  $ceph_deploy_user,
  $ceph_primary_mon,
  $ceph_cluster_interface,
  $ceph_cluster_network,
  $glance_ceph_pool,
  $cinder_rbd_pool,
){

  include cephdeploy

  $disk_hash = $name
  $disk_array = split($disk_hash, ':')
  $disk = $disk_array[0]
  $disk_identifier = regsubst($disk_array[0], '.*/', '')
  $disk_journal = $disk_array[1]
  if $disk_journal {
    $disk_journal_real = $disk_journal
  } else {
    $disk_journal_real = $disk
  }

  exec { "create osd $disk":
     cwd     => "/home/$ceph_deploy_user/bootstrap",
     command => "/usr/bin/ceph-deploy --overwrite-conf osd create $::hostname:$disk:$disk_journal_real",
     require => Exec["zap $disk"],
     unless  => "/usr/bin/test -e /home/$ceph_deploy_user/zapped/$disk_identifier",
  }

  exec { "get config $disk":
    cwd     => "/home/$ceph_deploy_user/bootstrap",
    user    => $ceph_deploy_user,
    command => "/usr/bin/sudo /usr/bin/ceph-deploy config push $::hostname",
    require => [ Exec['install ceph'], File['/etc/ceph/ceph.conf'] ],
    unless  => '/usr/bin/test -e /etc/ceph/ceph.conf',
  }

  exec { "gatherkeys_$disk":
    command => "/usr/bin/scp $ceph_deploy_user@$ceph_primary_mon:bootstrap/*.key* .",
    user    => $ceph_deploy_user,
    cwd     => "/home/$ceph_deploy_user/bootstrap",
    require => [ Exec['install ceph'], File["/etc/sudoers.d/$ceph_deploy_user"], Exec["get config $disk"] ],
    unless  => '/usr/bin/test -e /home/$ceph_deploy_user/bootstrap/$cluster.bootstrap-osd.keyring',
  }

  exec {"copy admin key $disk":
    command => "/bin/cp /home/$ceph_deploy_user/bootstrap/ceph.client.admin.keyring /etc/ceph",
    unless  => '/usr/bin/test -e /etc/ceph/ceph.client.admin.keyring',
    require => Exec["gatherkeys_$disk"],
  }

  exec { "zap $disk":
    cwd     => "/home/$ceph_deploy_user/bootstrap",
    command => "/usr/bin/ceph-deploy disk zap $::hostname:$disk",
    require => [ Exec['install ceph'], Exec["gatherkeys_$disk"] ],
    unless  => "/usr/bin/test -e /home/$ceph_deploy_user/zapped/$disk_identifier",
  }

  file { "/home/$ceph_deploy_user/zapped/$disk_identifier":
    ensure  => present,
    require => [ Exec["zap $disk"], Exec["create osd $disk"], File["/home/$ceph_deploy_user/zapped"] ],
  }

  exec {"iptables osd $disk":
    command => "/sbin/iptables -A INPUT -i $ceph_cluster_interface  -m multiport -p tcp -s $ceph_cluster_network --dports 6800:6810 -j ACCEPT",
    unless  => '/sbin/iptables -L | grep "multiport dports 6800:6810"',
  }

  if $setup_pools {

    exec { "create glance images pool $disk":
      command => "/usr/bin/ceph osd pool create $glance_ceph_pool 128",
      unless  => "/usr/bin/rados lspools | grep -sq $glance_ceph_pool",
      require => Exec["create osd $disk"],
    }

    exec { "create cinder volumes pool $disk":
      command => "/usr/bin/ceph osd pool create $cinder_rbd_pool 128",
      unless  => "/usr/bin/rados lspools | grep -sq $cinder_rbd_pool",
      require => Exec["create osd $disk"],
    }

  }


}

