define cephdeploy::apt (
  $release,
) {
  apt::key { 'ceph':
    key => '17ED316D',
    key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
  }

  apt::source { 'ceph':
    location => "http://ceph.com/debian-${release}/",
    release => $::lsbdistcodename,
    require => Apt::Key['ceph'],
    before => Package['ceph-deploy'],
  }

  apt::source { 'ceph-extras':
    location => "http://ceph.com/packages/ceph-extras/debian/",
    release => $::lsbdistcodename,
    require => Apt::Key['ceph'],
    before => Package['ceph-deploy'],
  }
}
