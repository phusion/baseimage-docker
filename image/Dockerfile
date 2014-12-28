FROM armv7/ubuntu_core:14.10
MAINTAINER Uli Middelberg <armv7@midelberg.de>

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

RUN mkdir /build
ADD . /build

RUN /build/prepare.sh && \
	/build/system_services.sh && \
	/build/utilities.sh && \
	/build/cleanup.sh

CMD ["/sbin/my_init"]
