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
# [*ceph_deploy_user*]
#   (required) The cephdeploy account username
#
# [*ceph_public_interface*]
#   (required) The interface for MON to listen on.
#
# [*ceph_public_network*]
#   (required) The client-facing network.
#
# [*ceph_primary_mon*]
#   (required) The primary MON in the monmap.
#
# [*ceph_cluster_name*]
#   (required) The ceph cluster name.
#


class cephdeploy::mon(
  $ceph_deploy_user,
  $ceph_public_interface,
  $ceph_public_network,
  $ceph_primary_mon,
  $ceph_cluster_name,
){

#  include cephdeploy

  exec { 'create mon':
    cwd      => "/home/$ceph_deploy_user/bootstrap",
    command  => "/usr/bin/ceph-deploy mon create $::hostname",
    unless   => '/usr/bin/sudo /usr/bin/ceph --cluster=ceph --admin-daemon /var/run/ceph/`hostname -s`-mon.ceph.asok mon_status',
    require  => Exec['install ceph'],
    provider => shell,
  }

  if $ceph_primary_mon == $::hostname {
    exec { 'copy keys':
      path => '/bin:/usr/bin',
      command => "cp /var/lib/ceph/bootstrap-mds/$ceph_cluster_name.keyring /home/$ceph_deploy_user/bootstrap/$ceph_cluster_name.bootstrap-mds.keyring &&
cp /var/lib/ceph/bootstrap-osd/$ceph_cluster_name.keyring /home/$ceph_deploy_user/bootstrap/$ceph_cluster_name.bootstrap-osd.keyring &&
cp /etc/ceph/ceph.client.admin.keyring /home/$ceph_deploy_user/bootstrap/ceph.client.admin.keyring &&
cp /var/lib/ceph/mon/ceph-$ceph_primary_mon/keyring /home/$ceph_deploy_user/bootstrap/ceph.mon.keyring &&
chown $ceph_deploy_user:$ceph_deploy_user /home/$ceph_deploy_user/bootstrap/* &&
chmod 644 /home/$ceph_deploy_user/bootstrap/*
",
      require => Exec['create mon'],
      unless => "/usr/bin/test -e /home/$ceph_deploy_user/bootstrap/$cluster.bootstrap-osd.keyring",
    }
  }

  exec {'iptables mon':
    command => "/sbin/iptables -A INPUT -i $ceph_public_interface -p tcp -s $ceph_public_network --dport 6789 -j ACCEPT",
    unless  => '/sbin/iptables -L | grep "tcp dpt:6789"',
  }


}
