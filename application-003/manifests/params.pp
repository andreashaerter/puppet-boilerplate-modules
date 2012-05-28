# == Class: boilerplate::params
#
# Sets the default values for the parameters of the main module class (see
# <tt>init.pp</tt>) and manages internal module variables.
#
# This class exists to
# 1. Declutter the default value assignment for the parameters of the main
#    module class.
# 2. Manage internally used module variables in a central place.
#
# Therefore, many operating system dependent differences (names, paths, ...)
# are addressed in here.
#
# Have a look at the corresponding <tt>init.pp</tt> manifest file if you need
# more technical information about how the values of this class are used as
# parameter defaults for the main module class.
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

  # autoload_class
  $autoload_class = false

  # packages
  case $::operatingsystem { # see http://j.mp/x6Mtba for a list of known values
    'CentOS', 'Fedora', 'Scientific': {
      $package = [ 'FIXME/TODO' ]
    }
    'Debian', 'Ubuntu': {
      $package = [ 'FIXME/TODO' ]
    }
    default: {
      fail("\"${module_name}\" provides no package default value for \"${::operatingsystem}\"")
    }
  }

  # debug
  $debug = false



  #### Internal module values

  # nothing right now

}
