# == Class: boilerplate::config
#
# FIXME/TODO Please check if you want to remove this class because it may be
#            unnecessary for your module. Don't forget to update the class
#            declarations and relationships at init.pp afterwards (the relevant
#            parts are marked with "FIXME/TODO" comments).
#
# This class exists to coordinate all configuration related actions,
# functionality and logical units in a central place.
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
#   class { 'boilerplate::config': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * John Doe <mailto:john.doe@example.com>
#
class boilerplate::config {

  #### Configuration

  # nothing right now

  # Helpful snippet(s):
  #
  # Config file. See 'file' doc at http://j.mp/wKju0C for information.
  # file { 'boilerplate_config':
  #   ensure  => 'present',
  #   path    => '/etc/boilerplate/boilerplate.conf',
  #   mode    => '0644',
  #   owner   => 'root',
  #   group   => 'root',
  #   # If you specify multiple file sources for a file, then the first source
  #   # that exists will be used.
  #   source  => [
  #     "puppet:///modules/boilerplate/config.cfg-$::fqdn",
  #     "puppet:///modules/boilerplate/config.cfg-$::hostname",
  #     'puppet:///modules/boilerplate/config.cfg'
  #   ],
  #   content => template('boilerplate/config.erb'),
  #   notify  => Service['boilerplate'],
  # }

}
