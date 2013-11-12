# A minimal Docker base image with a correct and usable system

Baseimage-docker is a [Docker](http://www.docker.io) image meant to serve as a good base for any other Docker container. It contains a minimal base system with the most important things already installed and set up correctly.

Included in the image are:

| Component     | Why is it included? / Remarks | Remarks |
| ------------- | ------------------- | ------- |
| Ubuntu 12.04 LTS | The base system. | |
| syslog-ng | A syslog daemon is necessary so that many services - including the kernel itself - can correctly log to /var/log/syslog. If no syslog daemon is running, a lot of important messages are silently swallowed. <br>Only listens locally. | Only listens locally. |
| ssh server | | |
| [runit](http://smarden.org/runit/) | For service supervision and management. Much easier to use than SysV init and supports restarting daemons when they crash. Much easier to use and more lightweight than Upstart. | |

 * The SSH server, so that you can easily login to your container to inspect or administer things.
   * Password and challenge-response authentication are disabled by default. Only key authentication is allowed.
   * It allows an predefined key by default to make debugging easy. You should replace this ASAP. See instructions.

Why use baseimage-docker instead of doing everything yourself in Dockerfile?

    # Use phusion/baseimage as base image. To make your builds reproducible, make
    # sure you lock down to a specific version, not to `latest`!
    FROM phusion/baseimage:<VERSION>
    
    # Remove authentication rights for insecure_key.
    RUN rm -f /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys
    
    # Use baseimage-docker's init process.
    CMD ["/sbin/my_init"]
    
    # ...put other build instructions here...
    
    # Clean up APT when done.
    RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
