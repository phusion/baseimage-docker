FROM ubuntu:14.04
MAINTAINER Gianpaolo Macario <gmacario@gmail.com>

ENV HOME /root
RUN mkdir /build
ADD . /build

RUN /build/prepare.sh && \
	/build/system_services.sh && \
	/build/utilities.sh && \
	/build/cleanup.sh

# Create mountpoint for Vagrant synced folder
RUN mkdir -p /vagrant

CMD ["/sbin/my_init"]
