# Definition: tomcat::config::server::globalnamingresource
#
# Configure GlobalNamingResources Resource elements in $CATALINA_BASE/conf/server.xml
#
# Parameters:
# - $catalina_base is the base directory for the Tomcat installation.
# - $resource_ensure specifies whether you are trying to add or remove the
#   Resource element. Valid values are 'true', 'false', 'present', and
#   'absent'. Defaults to 'present'.
# - An optional hash of $additional_attributes to add to the Resource. Should
#   be of the format 'attribute' => 'value'.
# - An optional array of $attributes_to_remove from the Resource.
define tomcat::config::server::globalnamingresource (
  $catalina_base         = $::tomcat::catalina_home,
  $resource_ensure      = 'present',
  $additional_attributes = {},
  $attributes_to_remove  = [],
  $server_config         = undef,
) {
  if versioncmp($::augeasversion, '1.0.0') < 0 {
    fail('Server configurations require Augeas >= 1.0.0')
  }

  validate_re($resource_ensure, '^(present|absent|true|false)$')
  validate_hash($additional_attributes)
  validate_re($catalina_base, '^.*[^/]$', '$catalina_base must not end in a /!')

  if $server_config {
    $_server_config = $server_config
  } else {
    $_server_config = "${catalina_base}/conf/server.xml"
  }

  $base_path = "Server/GlobalNamingResources/Resource[#attribute/name='${name}']"
  if $resource_ensure =~ /^(absent|false)$/ {
    $changes = "rm ${base_path}"
  } else {
    ## make the object
    $_make_path = "set Server/GlobalNamingResources/Resource[#attribute/name='${name}']/#attribute/name '${name}'"
    if ! empty($additional_attributes) {
      $_additional_attributes = join(suffix(join_keys_to_values(prefix(delete($additional_attributes,'name'), "set ${base_path}/#attribute/"), " '"),"'"),"\n")
      #notify{"joined additional_attributes ${_additional_attributes}":}
    } else {
      $_additional_attributes = undef
    }
    if ! empty(any2array($attributes_to_remove)) {
      $_additional_attributes = join(keys(prefix($additional_attributes, "rm ${base_path}/#attribute/")),"\n")
    } else {
      $_attributes_to_remove = undef
    }

    $_changes = delete_undef_values(flatten([ $_additional_attributes, $_attributes_to_remove ]))
    $changes = "${_make_path}\n${_changes}"
  }

  $timestamp = generate('/bin/date', '+%Y%d%m_%H:%M:%S:%N')
  $tmpfilename = regsubst($name, '/', '__', 'G')
  file {"/tmp/globalnamingresource-${tmpfilename}.aug-${timestamp}": content=>$changes }

  augeas { "server-${catalina_base}-globalresource-${name}":
    lens    => 'Xml.lns',
    incl    => $_server_config,
    changes => $changes,
    require => File[$_server_config],
  }
}
