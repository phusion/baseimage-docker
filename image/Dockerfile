FROM ubuntu:14.04
MAINTAINER Phusion <info@phusion.nl>

ENV HOME /root
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
RUN echo 'APT::Install-Recommends "0"; \n\
APT::Get::Assume-Yes "true"; \n\
APT::Get::force-yes "true"; \n\
APT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01buildconfig \
 && mkdir /build
ADD . /build

RUN /build/system_services.sh \
 && /build/utilities.sh \
 && /build/cleanup.sh

CMD ["/sbin/my_init"]
