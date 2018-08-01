# -*- mode: ruby -*-
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 2"

ENV['EVENT_NAME'] = ENV['EVENT_NAME'] || 'super'
ENV['EVENT_YEAR'] = ENV['EVENT_YEAR'] || '2019'


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "bento/ubuntu-18.04"
    config.vm.hostname = "localhost"

    config.vm.network :forwarded_port, guest: 8000, host: 8000 # haproxy http proxy
    config.vm.network :forwarded_port, guest: 4443, host: 4443 # haproxy https proxy
    config.vm.network :forwarded_port, guest: 8282, host: 8282 # cherrypy backend

    config.vm.synced_folder ".", "/home/vagrant/reggie-formula", create: true

    # No good can come from updating plugins.
    # Plus, this makes creating Vagrant instances MUCH faster.
    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
    end

    # This is the most amazing module ever, it caches anything you download with apt-get!
    # To install it: vagrant plugin install vagrant-cachier
    if Vagrant.has_plugin?("vagrant-cachier")
        # Configure cached packages to be shared between instances of the same base box.
        # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
        config.cache.scope = :box
    end

    config.vm.provider :virtualbox do |vb|
        vb.memory = 1536
        vb.cpus = 2
        vb.name = 'reggie (%s %s) %s' % [ENV['EVENT_NAME'], ENV['EVENT_YEAR'], Time.now.strftime("%Y-%m-%d %H:%M:%S.%L")]

        # Allow symlinks to be created in /home/vagrant/reggie-formula.
        # Modify "home_vagrant_reggie-formula" to be different if you change the path.
        # NOTE: requires Vagrant to be run as administrator for this to work.
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/home_vagrant_reggie-formula", "1"]
    end

    config.vm.provision :shell, env: {"EVENT_NAME"=>ENV['EVENT_NAME'], "EVENT_YEAR"=>ENV['EVENT_YEAR']}, inline: "
        set -e
        # Upgrade all packages to the latest version, very slow
        # export DEBIAN_FRONTEND=noninteractive
        # export DEBIAN_PRIORITY=critical
        # sudo -E apt-get -qy update
        # sudo -E apt-get -qy -o \"Dpkg::Options::=--force-confdef\" -o \"Dpkg::Options::=--force-confold\" upgrade
        # sudo -E apt-get -qy autoclean
        sudo -E apt-get -qy -o \"Dpkg::Options::=--force-confdef\" -o \"Dpkg::Options::=--force-confold\" install libssh-dev python-git swapspace

        mkdir -p /etc/salt
        cat >> /etc/salt/grains << EOF
event_name: ${EVENT_NAME}
event_year: ${EVENT_YEAR}
EOF

"

    config.vm.provision :salt do |salt|
        salt.masterless = true
        salt.install_type = "git"
        salt.install_args = "v2018.3.2"
        salt.minion_config = "vagrant/salt/vagrant/files/salt_minion.conf"
        salt.minion_id = "reggie"
        salt.run_highstate = true
        salt.colorize = true
        salt.log_level = "info"
        salt.verbose = true
    end

    config.vm.post_up_message = "
  All done!
      event_name: #{ENV['EVENT_NAME']}
      event_year: #{ENV['EVENT_YEAR']}

  To login to your new development machine run:
      vagrant ssh

  The machine is configured using salt locally:
      sudo salt-call --local state.apply

  Several shortcut aliases have been installed for you:
      alias salt-local='sudo salt-call --local'
      alias salt-apply='sudo salt-call --local state.apply'
      alias run_server='reggie-formula/reggie-deploy/env/bin/python reggie-formula/reggie-deploy/run_server.py'

  The reggie virtualenv has been added to your path, along with a custom python startup:
      export PYTHONSTARTUP='/home/vagrant/.pythonstartup.py'
      export PATH=\"reggie-formula/reggie-deploy/env/bin:$PATH\"

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
end
