## manage the catalina.properties file

define tomcat::config::properties (
  $catalina_base,
  $catalina_home,
  $file    = 'conf/catalina.properties',
  $srcfile = 'conf/catalina.properties',
) {
  concat { "${catalina_base}/${file}":
    ensure => present,
  }
  concat::fragment { "${catalina_base} properties base file from catalina_home ${$catalina_home}/${srcfile}":
    target => "${catalina_base}/${file}",
    source => "${catalina_home}/${srcfile}",
    order  => 01,
  }
}
