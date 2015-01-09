FROM armv7/ubuntu_core:14.04
MAINTAINER Phusion <info@phusion.nl>

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

RUN mkdir /build
ADD . /build

RUN /build/prepare.sh && \
	/build/system_services.sh && \
	/build/utilities.sh && \
	/build/cleanup.sh

CMD ["/sbin/my_init"]
