# == Class artifactory::config
#
# This class is called from artifactory for service config.
#
class artifactory::config {
  # Install storage.properties if Available
  if(
    $::artifactory::db_url or
    $::artifactory::db_username or
    $::artifactory::db_password or
    $::artifactory::db_type) {
    if ($::artifactory::db_url and
        $::artifactory::db_username and
        $::artifactory::db_password and
        $::artifactory::db_type
        ) {

      file { "${::artifactory::artifactory_home}/etc/.secrets":
        ensure => directory,
        owner  => 'artifactory',
        group  => 'artifactory',
      }

      file { "${::artifactory::artifactory_home}/etc/.secrets/.temp.db.properties":
        ensure  => file,
        content => epp(
          'artifactory/db.properties.epp',
          {
            db_url                         => $::artifactory::db_url,
            db_username                    => $::artifactory::db_username,
            db_password                    => $::artifactory::db_password,
            db_type                        => $::artifactory::db_type,
            binary_provider_type           => $::artifactory::binary_provider_type,
            pool_max_active                => $::artifactory::pool_max_active,
            pool_max_idle                  => $::artifactory::pool_max_idle,
            binary_provider_cache_maxsize  => $::artifactory::binary_provider_cache_maxsize,
            binary_provider_base_data_dir  => $::artifactory::binary_provider_base_data_dir,
            binary_provider_filesystem_dir => $::artifactory::binary_provider_filesystem_dir,
            binary_provider_cache_dir      => $::artifactory::binary_provider_cache_dir,
          }
        ),
        mode    => '0640',
        owner   => 'artifactory',
        group   => 'artifactory',
      }
      # Ensuring local db works
      file { 'java_profile':
        ensure  => present,
        path    => '/etc/profile.d/',
        content => "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.191.b12-1.el7_6.x86_64 \n export ARTIFACTORY_HOME=${::artifactory::artifactory_home}",# lint:ignore:140chars
        user    => 'root'
      }

      file { "${::artifactory::artifactory_home}/etc/storage.properties":
        ensure => link,
        target => "${::artifactory::artifactory_home}/etc/.secrets/.temp.db.properties",
      }

      file { "${::artifasctory::artifactory_home}/etc/binarystore.xml":
        ensure  => file,
        content => epp(
          'artifactory/binarystore.xml.epp',
          {
            binary_provider_type           => $::artifactory::binary_provider_type,
            binary_provider_cache_maxsize  => $::artifactory::binary_provider_cache_maxsize,
            binary_provider_base_data_dir  => $::artifactory::binary_provider_base_data_dir,
            binary_provider_filesystem_dir => $::artifactory::binary_provider_filesystem_dir,
            binary_provider_cache_dir      => $::artifactory::binary_provider_cache_dir,
          }
        ),
      }

      if ($::artifactory::jdbc_driver_url) {
        $file_name =  regsubst($::artifactory::jdbc_driver_url, '.+\/([^\/]+)$', '\1')

        file { "${::artifactory::artifactory_home}/tomcat/lib/${file_name}":
          source => $::artifactory::jdbc_driver_url,
          mode   => '0775',
          owner  => 'root',
        }
      }
    }
    else {
      warning('Database port, hostname, username, password and type must be all be set, or not set. Install proceeding without storage.')
    }
  }
  if ($::artifactory::master_key) {
    file { "${::artifactory::artifactory_home}/etc/security":
      ensure => directory,
      owner  => 'artifactory',
      group  => 'artifactory',
    }

    file { "${::artifactory::artifactory_home}/etc/security/master.key":
      ensure  => file,
      content => $::artifactory::master_key,
      mode    => '0640',
      owner   => 'artifactory',
      group   => 'artifactory',
    }
  }
  # exec { 'artifactory home':
  #     command => "export ARTIFACTORY_HOME=${::artifactory::artifactory_home}",
  #     path    => '/opt/jfrog/artifactory/tomcat/bin/',
  #     user    => 'artifactory',
  # }
  # file_line { 'artifactory_home':0
  #     ensure => present,
  #     path   => '/etc/opt/jfrog/artifactory/default',
  #     line   => "export ARTIFACTORY_HOME=${::artifactory::artifactory_home}",
  #     match  => 'export ARTFACTORY_HOME='
  #
  #     }
}
