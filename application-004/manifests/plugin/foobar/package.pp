# == Class: boilerplate::plugin::foobar::package
#
# FIXME/TODO Replace all occurrences of "foobar" with the name of the plugin you
#            want to manage.
#
# This class exists to coordinate all software package management related
# actions, functionality and logical units in a central place.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'boilerplate::plugin::foobar::package': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * John Doe <mailto:john.doe@example.com>
#
class boilerplate::plugin::foobar::package {

  #### Package management

  # set params: in operation
  if $boilerplate::plugin::foobar::ensure == 'present' {

    $package_ensure = $boilerplate::plugin::foobar::autoupgrade ? {
      true  => 'latest',
      false => 'present',
    }

  # set params: removal
  } else {
    $package_ensure = 'purged'
  }

  # action
  package { $boilerplate::params::package_plugin_foobar:
    ensure => $package_ensure,
  }

}
