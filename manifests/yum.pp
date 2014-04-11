define cephdeploy::yum (
  $release,
) {
  case $::osfamily {
    'RedHat': {
      $system = "rhel6"
      $system_extras = "rhel6"
    }
    'Suse': {
      $system = "sles11"
      $system_extras = "sles11sp2"
    }
  }

  yumrepo { 'ceph':
    descr => "Ceph ${release} repository",
    baseurl => "http://ceph.com/rpm-${release}/${system}/x86_64/",
    gpgkey =>
      'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
    gpgcheck => 1,
    enabled => 1,
    priority => 5,
    before => Package['ceph-deploy'],
  }

  yumrepo { 'ceph-noarch':
    descr => "Ceph ${release} noarch repository",
    baseurl => "http://ceph.com/rpm-${release}/${system}/noarch/",
    gpgkey =>
      'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
    gpgcheck => 1,
    enabled => 1,
    priority => 5,
    before => Package['ceph-deploy'],
  }

  yumrepo { 'ceph-extras':
    descr => "Ceph Extras repository",
    baseurl => "http://ceph.com/packages/ceph-extras/rpm/${system_extras}/x86_64/",
    gpgkey =>
      'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
    gpgcheck => 1,
    enabled => 1,
    priority => 5,
    before => Package['ceph-deploy'],
  }

  yumrepo { 'ceph-extras-noarch':
    descr => "Ceph Extras repository",
    baseurl => "http://ceph.com/packages/ceph-extras/rpm/${system_extras}/noarch/",
    gpgkey =>
      'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
    gpgcheck => 1,
    enabled => 1,
    priority => 5,
    before => Package['ceph-deploy'],
  }
}

