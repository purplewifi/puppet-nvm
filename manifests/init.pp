# See README.md for usage information
class nvm (
  $user,
  $home                = undef,
  $nvm_dir             = undef,
  $profile_path        = undef,
  $version             = $nvm::params::version,
  $manage_user         = $nvm::params::manage_user,
  $manage_dependencies = $nvm::params::manage_dependencies,
  $manage_profile      = $nvm::params::manage_profile,
  $nvm_repo            = $nvm::params::nvm_repo,
  $refetch             = $nvm::params::refetch,
  $install_node        = $nvm::params::install_node,
  $node_instances      = $nvm::params::node_instances,
) inherits nvm::params {
  if $home == undef and $user == 'root' {
    $final_home = '/root'
  }
  elsif $home == undef {
    $final_home = "/home/${user}"
  }
  else {
    $final_home = $home
  }

  if $nvm_dir == undef {
    $final_nvm_dir = "/home/${user}/.nvm"
  }
  else {
    $final_nvm_dir = $nvm_dir
  }

  if $profile_path == undef {
    $final_profile_path = "/home/${user}/.bashrc"
  }
  else {
    $final_profile_path = $profile_path
  }

  assert_type(String[1], $user)
  assert_type(String[1], $final_home)
  assert_type(String[1], $final_nvm_dir)
  assert_type(String[1], $final_profile_path)
  assert_type(String[1], $version)
  assert_type(Boolean, $manage_user)
  assert_type(Boolean, $manage_dependencies)
  assert_type(Boolean, $manage_profile)
  if $install_node {
    assert_type(String[1], $install_node)
  }
  assert_type(Hash, $node_instances)

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  if $manage_dependencies {
    $nvm_install_require = [Package['git', 'wget', 'make']]
    ensure_packages(['git', 'wget', 'make'])
  }
  else {
    $nvm_install_require = undef
  }

  if $manage_user {
    user { $user:
      ensure     => present,
      home       => $final_home,
      managehome => true,
      before     => Class['nvm::install'],
    }
  }

  class { 'nvm::install':
    user         => $user,
    home         => $final_home,
    version      => $version,
    nvm_dir      => $final_nvm_dir,
    nvm_repo     => $nvm_repo,
    dependencies => $nvm_install_require,
    refetch      => $refetch,
  }

  if $manage_profile {
    file { "ensure ${final_profile_path}":
      ensure => 'file',
      path   => $final_profile_path,
      owner  => $user,
    }

    -> file_line { 'add NVM_DIR to profile file':
      path => $final_profile_path,
      line => "export NVM_DIR=${final_nvm_dir}",
    }

    -> file_line { 'add . ~/.nvm/nvm.sh to profile file':
      path => $final_profile_path,
      line => "[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"  # This loads nvm",
    }
  }

  if $install_node {
    $final_node_instances = merge($node_instances, {
        "${install_node}" => {
          set_default => true,
        },
    })
  }
  else {
    $final_node_instances = $node_instances
  }

  create_resources(::nvm::node::install, $final_node_instances, {
      user        => $user,
      nvm_dir     => $final_nvm_dir,
  })
}
