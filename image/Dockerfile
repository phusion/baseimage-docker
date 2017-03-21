FROM ubuntu:16.04
MAINTAINER Phusion <info@phusion.nl>

COPY . /bd_build

RUN /bd_build/prepare.sh && \
	/bd_build/system_services.sh && \
	/bd_build/utilities.sh && \
	/bd_build/fix_pam_bug.sh && \
	/bd_build/cleanup.sh

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

CMD ["/sbin/my_init"]
