FROM ubuntu:14.04
MAINTAINER Gianpaolo Macario <gmacario@gmail.com>

# Create mountpoint for Vagrant synced folder
RUN mkdir -p /vagrant

ENV HOME /root
RUN mkdir /build
ADD . /build

# Create user "vagrant"
RUN apt-get update
RUN apt-get -y install adduser
RUN adduser vagrant
# Change default password for user "vagrant"
RUN usermod -p $(perl -e 'print crypt("vagrant","\$6\$xx\$")') vagrant
# Allow user "vagrant" to become root without entering a password
RUN install -m 440 /build/etc_sudoers.d_vagrant /etc/sudoers.d/vagrant

RUN /build/prepare.sh && \
	/build/system_services.sh && \
	/build/utilities.sh && \
	/build/cleanup.sh

# Create mountpoint for Vagrant synced folder
RUN mkdir -p /vagrant

CMD ["/sbin/my_init"]
