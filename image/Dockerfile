FROM debian:8.2
MAINTAINER Jim Riordan <jim@j1mr10rd4n.info>

ADD . /dbd_build

RUN /dbd_build/prepare.sh && \
	/dbd_build/system_services.sh && \
	/dbd_build/utilities.sh && \
	/dbd_build/cleanup.sh

CMD ["/sbin/my_init"]
