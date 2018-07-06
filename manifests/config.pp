class klbr_puppetagent::config {
    #The "master" value in Hiera determines wich template to use.
    $master                 = lookup('klbr_puppetagent::config:master')
    $puppet_env             = lookup('klbr_puppetagent::config:puppet_env')
    $puppet_desired_version = lookup('puppet_desired_version')

    if $puppet_desired_version == 4 or $puppet_desired_version == 5 {
        if $master == true {
            # we only need to use these variables if we're provisioning a puppetmaster
            $topleveldomain = lookup('klbr_puppetagent::config:topleveldomain')
            $dns_alt_names  = lookup('klbr_puppetagent::config:dns_alt_names') 
            $template       = "klbr_puppetagent/master.erb"
            exec { 'set permissions on puppet code directory for the puppet user':
                command => '/usr/bin/setfacl -Rdm u:puppet:r-X /etc/puppetlabs/code',
                unless  => '/usr/bin/getfacl /etc/puppetlabs/code | grep -q "default:user:puppet:r-x"',
                require => [
                    Package['acl'],
                ],
            }
        } else { 
            # if we are not a puppet master, select the client template
            $template       = "klbr_puppetagent/client.erb"    
        }
    } else {
        notify {
        'error':
            name     => 'Unknown Puppet Version',
            message  => 'I don\'t know what you want man, they only told me about Pupper version 4 and 5. What are we using nowadays?',
            withpath => true;
        }    
    }

    file { "/etc/puppetlabs/puppet":
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }
    file { "/etc/puppetlabs/puppet/puppet.conf":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("$template"), # as defined above
        require => Class["klbr_puppetagent::install"],
        notify  => Class["klbr_puppetagent::service"],
    }    
    file { "/etc/default/puppet":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/klbr_puppetagent/defaults',
        require => Class["klbr_puppetagent::install"],
        notify  => Class["klbr_puppetagent::service"],
    }
}