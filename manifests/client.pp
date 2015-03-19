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
# [*primary_mon*]
#   (require) The primary MON in the monmap.
#
# [*pass*]
#   (required) The cephdeploy account password.
#
# [*setup_virsh*]
#   (optional) Configure virsh with ceph secret.
#   This allows nova-compute to use rbd.


class cephdeploy::client(
  $ceph_deploy_user,
  $pass,
  $primary_mon,
  $setup_virsh = true,
){

## User setup

  user {$ceph_deploy_user:
    ensure   => present,
    password => $pass,
    home     => "/home/${ceph_deploy_user}",
    shell    => '/bin/bash',
  }

  file {"/home/${ceph_deploy_user}":
    ensure  => directory,
    owner   => $ceph_deploy_user,
    group   => $ceph_deploy_user,
    mode    => '0755',
    require => User[$ceph_deploy_user],
  }

  file {"/home/${ceph_deploy_user}/.ssh":
    ensure  => directory,
    owner   => $ceph_deploy_user,
    group   => $ceph_deploy_user,
    mode    => '0700',
    require => File["/home/${ceph_deploy_user}"],
  }

  file {"/home/${ceph_deploy_user}/.ssh/id_rsa":
    content => template('cephdeploy/id_rsa.erb'),
    owner   => $ceph_deploy_user,
    group   => $ceph_deploy_user,
    mode    => '0600',
    require => File["/home/${ceph_deploy_user}/.ssh"],
  }

  file {"/home/${ceph_deploy_user}/.ssh/id_rsa.pub":
    content => template('cephdeploy/id_rsa.pub.erb'),
    owner   => $ceph_deploy_user,
    group   => $ceph_deploy_user,
    mode    => '0644',
    require => File["/home/${ceph_deploy_user}/.ssh"],
  }

  file {"/home/${ceph_deploy_user}/.ssh/authorized_keys":
    content => template('cephdeploy/id_rsa.pub.erb'),
    owner   => $ceph_deploy_user,
    group   => $ceph_deploy_user,
    mode    => '0600',
    require => File["/home/${ceph_deploy_user}/.ssh"],
  }

  file {"/home/${ceph_deploy_user}/.ssh/config":
    content => template('cephdeploy/config.erb'),
    owner   => $ceph_deploy_user,
    group   => $ceph_deploy_user,
    mode    => '0600',
    require => File["/home/${ceph_deploy_user}/.ssh"],
  }

  exec {'passwordless sudo for ceph deploy user':
    command => "/bin/echo \"${ceph_deploy_user} ALL = (root) NOPASSWD:ALL\"\
                 | sudo tee /etc/sudoers.d/${ceph_deploy_user}",
    unless  => "/usr/bin/test -e /etc/sudoers.d/${ceph_deploy_user}",
  }

  file {"/etc/sudoers.d/${ceph_deploy_user}":
    mode    => '0440',
    require => Exec['passwordless sudo for ceph deploy user'],
  }

  file {"/home/${ceph_deploy_user}/bootstrap":
    ensure  => directory,
    owner   => $ceph_deploy_user,
    group   => $ceph_deploy_user,
    require => File["/home/${ceph_deploy_user}"],
  }

  # install ceph client packages

  package {'ceph-common':
    ensure  => present,
    require => File["/home/${ceph_deploy_user}/bootstrap"],
  }

  package {'python-ceph':
    ensure  => present,
    require => File["/home/${ceph_deploy_user}/bootstrap"],
  }

  file { '/etc/ceph':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    require => Package['ceph-common'],
  }

  # get and install config and keys

  exec { 'get keys':
    command => "/usr/bin/scp ${ceph_deploy_user}@${primary_mon}:bootstrap/{*.key*,ceph.conf} .",
    user    => $ceph_deploy_user,
    cwd     => "/home/${ceph_deploy_user}/bootstrap",
    require => [ File["/home/${ceph_deploy_user}/bootstrap"], File["/home/${ceph_deploy_user}/.ssh/config"] ],
    unless  => "/usr/bin/test -e /home/${ceph_deploy_user}/bootstrap/ceph.conf",
  }

  exec { 'place keys':
    command => "/bin/cp /home/${ceph_deploy_user}/bootstrap/* /etc/ceph/",
    cwd     => "/home/${ceph_deploy_user}/bootstrap",
    require => [ Exec['get keys'], File['/etc/ceph'] ],
    unless  => '/usr/bin/test -e /etc/ceph/ceph.conf',
  }


  if $setup_virsh {

    if !defined(Package['libvirt']) {
      package {'libvirt':
        ensure => installed,
      }
    }

    file { '/etc/ceph/secret.xml':
      content => template('cephdeploy/secret.xml-compute.erb'),
      require => Package['ceph-common'],
    }

    exec { 'get-or-set virsh secret':
      command => '/usr/bin/virsh secret-define --file /etc/ceph/secret.xml | /usr/bin/awk \'{print $2}\' | sed \'/^$/d\' > /etc/ceph/virsh.secret',
      creates => '/etc/ceph/virsh.secret',
      require => [ Package['libvirt'], File['/etc/ceph/secret.xml'] ],
    }

    exec { 'set-secret-value virsh':
      command => "/usr/bin/virsh secret-set-value --secret $(cat /etc/ceph/virsh.secret) --base64 $(ceph auth get-key client.admin)",
      require => Exec['get-or-set virsh secret'],
    }

  }




}
