# -*- mode: ruby -*-
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'
VAGRANTFILE_API_VERSION = '2'
Vagrant.require_version '>= 2'

ENV['EVENT_NAME'] = ENV['EVENT_NAME'] || 'super'
ENV['EVENT_YEAR'] = ENV['EVENT_YEAR'] || '2019'

if Vagrant::Util::Platform.windows?
    ENV['IS_VAGRANT_WINDOWS'] = 'true'
else
    ENV['IS_VAGRANT_WINDOWS'] = 'false'
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = 'bento/ubuntu-18.04'
    config.vm.hostname = 'localhost'

    config.vm.network :forwarded_port, guest: 8000, host: 8000 # haproxy http proxy
    config.vm.network :forwarded_port, guest: 4443, host: 4443 # haproxy https proxy
    config.vm.network :forwarded_port, guest: 8282, host: 8282 # cherrypy backend

    config.vm.synced_folder '.', '/home/vagrant/reggie-formula', type: "rsync"
    #if Vagrant::Util::Platform.linux?
    #config.vm.synced_folder '.', '/home/vagrant/reggie-formula', type: "nfs"
    #end
    if Vagrant.has_plugin?('vagrant-unison2')
        # Required vagrant-unison2 configs 
        config.sync.host_folder = "."  #relative to the folder your Vagrantfile is in
        config.sync.guest_folder = "reggie-formula/" #relative to the vagrant home folder -> /home/vagrant 
      
        # Optional configs
        # File patterns to ignore when syncing. Ensure you don't have spaces between the commas!
        #config.unison.ignore = "Name {.DS_Store,.git,node_modules}" # Default: none

        # SSH connection details for Vagrant to communicate with VM.
        #config.unison.ssh_host = "10.0.0.1" # Default: '127.0.0.1'
        #config.unison.ssh_port = 22 # Default: 2222
        #config.unison.ssh_user = "deploy" # Default: 'vagrant'
        #config.unison.perms = 0 # if you get "properties changed on both sides" error 

        # `vagrant unison-sync-polling` command will restart unison in VM if memory
        # usage gets above this threshold (in MB).
        #config.unison.mem_cap_mb = 500 # Default: 200

        # Change polling interval (in seconds) at which to sync changes
        #config.unison.repeat = 5 # Default: 1
    end
        


    # No good can come from updating plugins.
    # Plus, this makes creating Vagrant instances MUCH faster.
    if Vagrant.has_plugin?('vagrant-vbguest')
        config.vbguest.auto_update = false
    end

    # This is the most amazing module ever, it caches anything you download with apt-get!
    # To install it: vagrant plugin install vagrant-cachier
    if Vagrant.has_plugin?('vagrant-cachier')
        # Configure cached packages to be shared between instances of the same base box.
        # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
        config.cache.scope = :box
    end

    config.vm.provider :virtualbox do |vb|
        vb.memory = 1536
        vb.cpus = 2
        if Vagrant::Util::Platform.windows?
            # don't use colons (:) or parens in windows filenames, will cause vagrant up to fail
            vb.name = 'reggie %s %s %s' % [ENV['EVENT_NAME'], ENV['EVENT_YEAR'], Time.now.strftime('%Y-%m-%d %s')]
        else
            vb.name = 'reggie (%s %s) %s' % [ENV['EVENT_NAME'], ENV['EVENT_YEAR'], Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')]
        end if

        # Allow symlinks to be created in /home/vagrant/reggie-formula.
        # Modify "home_vagrant_reggie-formula" to be different if you change the path.
        # NOTE: requires Vagrant to be run as administrator for this to work.
        vb.customize ['setextradata', :id, 'VBoxInternal2/SharedFoldersEnableSymlinksCreate/home_vagrant_reggie-formula', '1']
    end

    config.vm.provision :shell, env: {
        'EVENT_NAME'=>ENV['EVENT_NAME'],
        'EVENT_YEAR'=>ENV['EVENT_YEAR'],
        'IS_VAGRANT_WINDOWS'=>ENV['IS_VAGRANT_WINDOWS']
        }, inline: "
        set -e

        # Upgrade all packages to the latest version, commented out because it\'s very slow
        # export DEBIAN_FRONTEND=noninteractive
        # export DEBIAN_PRIORITY=critical
        # sudo -E apt-get -qy update
        # sudo -E apt-get -qy -o 'Dpkg::Options::=--force-confdef' -o 'Dpkg::Options::=--force-confold' upgrade
        # sudo -E apt-get -qy autoclean

        # Install some prerequisites
        sudo -E apt-get -qy install libssh-dev python-git swapspace

        # Create a sparse checkout of the infrastructure repo with only the reggie_config and reggie_state dirs
        if [ ! -d '/home/vagrant/reggie-formula/infrastructure/.git' ]; then
            git init /home/vagrant/reggie-formula/infrastructure
            cd /home/vagrant/reggie-formula/infrastructure
            git remote add origin https://github.com/magfest/infrastructure.git
            git config core.sparsecheckout true
            echo '/docs/*' >> .git/info/sparse-checkout
            echo '/reggie_config/*' >> .git/info/sparse-checkout
            echo '/reggie_state/*' >> .git/info/sparse-checkout
            echo '/README.md' >> .git/info/sparse-checkout
            git pull --depth=1 origin master
            git branch --set-upstream-to=origin/master master
        fi

        # Set up event grains
        mkdir -p /etc/salt
        echo \"event_name: ${EVENT_NAME}\" >> /etc/salt/grains
        echo \"event_year: ${EVENT_YEAR}\" >> /etc/salt/grains
        echo \"is_vagrant_windows: ${IS_VAGRANT_WINDOWS}\" >> /etc/salt/grains
"

    config.vm.provision :salt do |salt|
        salt.install_master = true
        salt.install_type = 'git'
        salt.install_args = 'v2018.3.2'
        salt.seed_master = {reggie: 'vagrant/vagrant/files/reggie.pub'}
        salt.master_config = 'vagrant/vagrant/files/salt_master.yaml'
        salt.minion_config = 'vagrant/vagrant/files/salt_minion.yaml'
        salt.minion_id = 'reggie'
        salt.minion_key = 'vagrant/vagrant/files/reggie.pem'
        salt.minion_pub = 'vagrant/vagrant/files/reggie.pub'
        salt.run_highstate = false
        salt.orchestrations = ['orchestration.vagrant_up']
        salt.colorize = true
        salt.log_level = 'info'
        salt.verbose = true
    end

    config.vm.post_up_message = "
  All done!
      event_name: #{ENV["EVENT_NAME"]}
      event_year: #{ENV["EVENT_YEAR"]}

  To login to your new development machine run:
      vagrant ssh

  The machine is configured using salt (minion id is 'reggie'):
      sudo salt reggie state.apply

  Shortcut aliases have been installed for you:
      alias run_server='reggie-formula/reggie_install/env/bin/python reggie-formula/reggie_install/run_server.py'

  The reggie virtualenv has been added to your path, along with a custom python startup:
      export PYTHONSTARTUP=\"/home/vagrant/.pythonstartup.py\"
      export PATH=\"reggie-formula/reggie_install/env/bin:$PATH\"

  The following services have been installed with systemd:
      reggie
        +- reggie-web
        +- reggie-worker
        +- reggie-scheduler

  You can access the web interface at:
      https://localhost:4443
      Username: magfest@example.com
      Password: magfest

"
        if Vagrant.has_plugin?('vagrant-unison2')
            config.vm.post_up_message = "Additional unison setup is required and edit reggie_up.sh to add 'vagrant unison-sync-polling' to the end of the file "
        end
end
