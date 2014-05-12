# -*- mode: ruby -*-
# vi: set ft=ruby :
ROOT = File.dirname(File.absolute_path(__FILE__))

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

# Default env properties which can be overridden
# Example overrides:
#   echo "ENV['PASSENGER_DOCKER_PATH'] ||= '../../phusion/passenger-docker'   " >> ~/.vagrant.d/Vagrantfile
#   echo "ENV['BASE_BOX_URL']          ||= 'd\:/dev/vm/vagrant/boxes/phusion/'" >> ~/.vagrant.d/Vagrantfile
BASE_BOX_URL          = ENV['BASE_BOX_URL']    || 'https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/'
VAGRANT_BOX_URL       = ENV['VAGRANT_BOX_URL'] || BASE_BOX_URL + 'ubuntu-14.04-amd64-vbox.box'
VMWARE_BOX_URL        = ENV['VMWARE_BOX_URL']  || BASE_BOX_URL + 'ubuntu-14.04-amd64-vmwarefusion.box'
BASEIMAGE_PATH        = ENV['BASEIMAGE_PATH' ] || '.'
PASSENGER_DOCKER_PATH = ENV['PASSENGER_PATH' ] || '../passenger-docker'
DOCKERIZER_PATH       = ENV['DOCKERIZER_PATH'] || '../dockerizer'

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
  config.vm.box = 'phusion-open-ubuntu-14.04-amd64'
  config.vm.box_url = VAGRANT_BOX_URL
  config.ssh.forward_agent = true
  passenger_docker_path = File.absolute_path(PASSENGER_DOCKER_PATH, ROOT)
  if File.directory?(passenger_docker_path)
    config.vm.synced_folder passenger_docker_path, '/vagrant/passenger-docker'
  end
  baseimage_path = File.absolute_path(BASEIMAGE_PATH, ROOT)
  if File.directory?(baseimage_path)
    config.vm.synced_folder baseimage_path, "/vagrant/baseimage-docker"
  end
  dockerizer_path = File.absolute_path(DOCKERIZER_PATH, ROOT)
  if File.directory?(dockerizer_path)
    config.vm.synced_folder dockerizer_path, '/vagrant/dockerizer'
  end

  config.vm.provider :vmware_fusion do |f, override|
    override.vm.box_url = VMWARE_BOX_URL
    f.vmx['displayName'] = 'baseimage-docker'
  end

  if Dir.glob("#{File.dirname(__FILE__)}/.vagrant/machines/default/*/id").empty?
    config.vm.provision :shell, :inline => $script
  end
end
