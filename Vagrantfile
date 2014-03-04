# -*- mode: ruby -*-
# vi: set ft=ruby :
ROOT = File.dirname(File.expand_path(__FILE__))

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

# Default env properties which can be overridden
# Example override: echo "ENV['PASSENGER_PATH_URI'] ||= '../../phusion/passenger-docker' # " >> ~/.vagrant.d/Vagrantfile
BASE_BOX_URL       = ENV['BASE_BOX_URL'      ] || 'https://oss-binaries.phusionpassenger.com/vagrant/boxes/'
VAGRANT_BOX_URL    = ENV['VAGRANT_BOX_URL'   ] || BASE_BOX_URL + 'ubuntu-12.04.3-amd64-vbox.box'
VMWARE_BOX_URL     = ENV['VMWARE_BOX_URL'    ] || BASE_BOX_URL + 'ubuntu-12.04.3-amd64-vmwarefusion.box'
PASSENGER_PATH_URI = ENV['PASSENGER_PATH_URI'] || '../passenger-docker'

$script = <<SCRIPT
wget -q -O - https://get.docker.io/gpg | apt-key add -
echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -q -y --force-yes lxc-docker
usermod -a -G docker vagrant
docker version
su - vagrant -c 'echo alias d=docker >> ~/.bash_aliases'
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'phusion-open-ubuntu-12.04-amd64'
  config.vm.box_url = VAGRANT_BOX_URL
  config.ssh.forward_agent = true
  passenger_path = "#{ROOT}/#{PASSENGER_PATH_URI}"
  if File.directory?(passenger_path)
    config.vm.synced_folder File.expand_path(passenger_path), '/vagrant/passenger-docker'
  end

  config.vm.provider :vmware_fusion do |f, override|
    override.vm.box_url = VMWARE_BOX_URL
    f.vmx['displayName'] = 'baseimage-docker'
  end

  if Dir.glob("#{File.dirname(__FILE__)}/.vagrant/machines/default/*/id").empty?
    config.vm.provision :shell, :inline => $script
  end
end
