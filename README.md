# A minimal Debian base image modified for Docker-friendliness

[![](https://badge.imagelayers.io/phusion/baseimage:0.9.17.svg)](https://imagelayers.io/?images=phusion/baseimage:latest 'Get your own badge on imagelayers.io')

Baseimage-docker is a special [Docker](https://www.docker.com) image that is configured for correct use within Docker containers. It is Debian, plus:

 * Modifications for Docker-friendliness.
 * Administration tools that are especially useful in the context of Docker.
 * Mechanisms for easily running multiple processes.

You can use it as a base for your own Docker images.

Baseimage-docker is available for pulling from [the Docker registry](https://registry.hub.docker.com/u/phusion/baseimage/)!

### Is this related to Phusion's Baseimage-docker?

Yes! This repository was forked from [Phusion's baseimage-docker](https://github.com/phusion/baseimage-docker). It's exactly the same except based on Debian 8.2 (Jessie) instead of Ubuntu. It was created mainly for learning about Docker images and different approaches to having a sane PID 1 processes in docker containers. See the README in the upstream repo for details.
