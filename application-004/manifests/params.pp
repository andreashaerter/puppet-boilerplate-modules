# == Class: boilerplate::params
#
# This class exists to
# 1. Declutter the default value assignment for class parameters.
# 2. Manage internally used module variables in a central place.
#
# Therefore, many operating system dependent differences (names, paths, ...)
# are addressed in here.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class is not intended to be used directly.
#
#
# === Links
#
# * {Puppet Docs: Using Parameterized Classes}[http://j.mp/nVpyWY]
#
#
# === Authors
#
# * John Doe <mailto:john.doe@example.com>
#
class boilerplate::params {

  #### Default values for the parameters of the main module class, init.pp

  # ensure
  $ensure = 'present'

  # autoupgrade
  $autoupgrade = false



  #### Default values for the parameters of the plugin::foobar class,    # FIXME/TODO: Replace "foobar" with the name of the plugin you you want to manage (all occurrences at the following 8 lines)
  #### plugin/foobar.pp

  # ensure
  $ensure_plugin_foobar = 'present'

  # autoupgrade
  $autoupgrade_plugin_foobar = false



  #### Internal module values

  # packages
  case $::operatingsystem {
    'CentOS', 'Fedora', 'Scientific': {
      # main application
      $package = [ 'FIXME/TODO' ]
      # plugins
      $package_plugin_foobar = [ 'FIXME/TODO' ]
    }
    'Debian', 'Ubuntu': {
      # main application
      $package = [ 'FIXME/TODO' ]
      # plugins
      $package_plugin_foobar = [ 'FIXME/TODO' ]
    }
    default: {
      fail("\"${module_name}\" provides no package default value for \"${::operatingsystem}\"")
    }
  }

}
