# == Class: boilerplate::plugin::foobar
#
# FIXME/TODO Replace all occurrences of "foobar" with the name of the plugin you
#            want to manage. Dont' forget to update the class default parameter
#            declaration params.pp afterwards (the relevant parts are marked
#            with "FIXME/TODO" comments). Rename this file and the
#            "manifests/plugin/foobar/" directory then.
#
# FIXME/TODO If the application's nomenclature does not call optional components
#            "plugin" but e.g. "extension", you may want to do the following
#            search and replace operations on all files of the module:
#              1. "boilerplate::plugin"  ->  "boilerplate::extension"
#              2. "_plugin"              ->  "_extension"
#              3. "plugins"              ->  "extensions"
#              4. "plugin"               ->  "extension"
#            Rename the directory "manifests/plugin/" to "manifests/extension/"
#            then.
#
# This class is able to install or remove the boilerplate plugin "foobar"
# on a node.
#
#
# === Parameters
#
# [*ensure*]
#   String. Controls if the managed resources shall be <tt>present</tt> or
#   <tt>absent</tt>. If set to <tt>absent</tt>:
#   * The managed software packages are being uninstalled.
#   * Any traces of the packages will be purged as good as possible. This may
#     include existing configuration files. The exact behavior is provider
#     dependent. Q.v.:
#     * Puppet type reference: {package, "purgeable"}[http://j.mp/xbxmNP]
#     * {Puppet's package provider source code}[http://j.mp/wtVCaL]
#   * System modifications (if any) will be reverted as good as possible
#     (e.g. removal of created users, services, changed log settings, ...).
#   * This is thus destructive and should be used with care.
#   Defaults to <tt>present</tt>.
#
# [*autoupgrade*]
#   Boolean. If set to <tt>true</tt>, any managed package gets upgraded
#   on each Puppet run when the package provider is able to find a newer
#   version than the present one. The exact behavior is provider dependent.
#   Q.v.:
#   * Puppet type reference: {package, "upgradeable"}[http://j.mp/xbxmNP]
#   * {Puppet's package provider source code}[http://j.mp/wtVCaL]
#   Defaults to <tt>false</tt>.
#
# The default values for the parameters are set in boilerplate::params. Have
# a look at the corresponding <tt>params.pp</tt> manifest file if you need more
# technical information about them.
#
#
# === Examples
#
# * Installation:
#     class { 'boilerplate::plugin::foobar': }
#
# * Removal/decommissioning:
#     class { 'boilerplate::plugin::foobar':
#       ensure => 'absent',
#     }
#
#
# === Authors
#
# * John Doe <mailto:john.doe@example.com>
#
class boilerplate::plugin::foobar(
  $ensure      = $boilerplate::params::ensure_plugin_foobar,
  $autoupgrade = $boilerplate::params::autoupgrade_plugin_foobar
) inherits boilerplate::params {

  #### Validate parameters

  # ensure
  if ! ($ensure in [ 'present', 'absent' ]) {
    fail("\"${ensure}\" is not a valid ensure parameter value")
  }

  # autoupgrade
  validate_bool($autoupgrade)



  #### Manage actions

  # package(s)
  class { 'boilerplate::plugin::foobar::package': }



  #### Manage relationships

  if !defined(Class['boilerplate']) {
    fail("Class \"${module_name}\" has to be evaluated before \"${module_name}::plugin::foobar\"")
  }

  if ($ensure == 'present') and ($boilerplate::ensure != 'present') {
    fail('Cannot ensure plugin presence if the main application is ensured absent.')
  }

  if $ensure == 'present' {
    # we need the main application before managing plugins
    Class['boilerplate']          -> Class['boilerplate::plugin::foobar']
    Class['boilerplate::package'] -> Class['boilerplate::plugin::foobar::package']

  } else {
    # there is currently no need for a specific removal order
  }

}
