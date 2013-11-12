# A minimal Docker base image with a correct and usable system

Baseimage-docker is a [Docker](http://www.docker.io) image meant to serve as a good base for any other Docker container. It contains a minimal base system with the most important things already installed and set up correctly.

 * **Github**: https://github.com/phusion/baseimage-docker
 * **Discussion forum**: https://groups.google.com/d/forum/passenger-docker
 * **Twitter**: https://twitter.com/phusion_nl
 * **Blog**: http://blog.phusion.nl/

### Why use baseimage-docker?

Why use baseimage-docker instead of doing everything yourself in Dockerfile?

 * It reduces the time needed to write a correct Dockerfile. You won't have to worry about the base system and can focus on your stack and your app.
 * It sets up the base system **correctly**. It's very easy to get the base system wrong, but this image does everything correctly.
 * It reduces the time needed to run `docker build`, allowing you to iterate your Dockerfile more quickly.

## Contents

*Looking for a more complete base image, one that is ideal for Ruby, Python, Node.js and Meteor web apps? Take a look at [passenger-docker](https://github.com/phusion/passenger-docker).*

| Component        | Why is it included? / Remarks |
| ---------------- | ------------------- |
| Ubuntu 12.04 LTS | The base system. |
| A **correct** init process | According to the Unix process model, [the init process](https://en.wikipedia.org/wiki/Init) -- PID 1 -- inherit all [orphaned child processes](https://en.wikipedia.org/wiki/Orphan_process) and must [reap them](https://en.wikipedia.org/wiki/Wait_(system_call)). Most Docker containers do not have an init process that does this correctly, and as a result their containers become filled with [zombie processes](https://en.wikipedia.org/wiki/Zombie_process) over time. Baseimage-docker comes with an init process `/sbin/my_init` that performs reaping correctly. |
| Fixes APT incompatibilities with Docker | See https://github.com/dotcloud/docker/issues/1024. |
| syslog-ng | A syslog daemon is necessary so that many services - including the kernel itself - can correctly log to /var/log/syslog. If no syslog daemon is running, a lot of important messages are silently swallowed. <br><br>Only listens locally. |
| ssh server | Allows you to easily login to your container to inspect or administer things. <br><br>Password and challenge-response authentication are disabled by default. Only key authentication is allowed.<br>It allows an predefined key by default to make debugging easy. You should replace this ASAP. See instructions. |
| cron | The cron daemon must be running for cron jobs to work. |
| [runit](http://smarden.org/runit/) | For service supervision and management. Much easier to use than SysV init and supports restarting daemons when they crash. Much easier to use and more lightweight than Upstart. |
| `setuser` | A tool for running a command as another user. Easier to use than `su`, has a smaller attack vector than `sudo`, and unlike `chpst` this tool sets `$HOME` correctly. Available as `/sbin/setuser`. |

Baseimage-docker is very lightweight: it only consumes 4 MB of memory.

### Wait, I thought Docker is about running a single process in a container?

Absolutely not true. Docker runs fine with multiple processes in a container. In fact, there is no technical reason why you should limit yourself to one process - it only makes things harder for you and breaks all kinds of essential system functionality, e.g. syslog.

Baseimage-docker *encourages* multiple processes through the use of runit.

## Inspecting baseimage-docker

To look around in the image, run:

    docker run -rm -t -i phusion/baseimage bash -l

You don't have to download anything manually. The above command will automatically pull the baseimage-docker image from the Docker registry.

## Using baseimage-docker as base image

The image is called `phusion/baseimage`, and is available on the Docker registry.

By default, it allows SSH access for the key in `image/insecure_key`. This makes it easy for you to login to the container, but you should replace this key as soon as possible.

    # Use phusion/baseimage as base image. To make your builds reproducible, make
    # sure you lock down to a specific version, not to `latest`!
    # See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
    # a list of version numbers.
    FROM phusion/baseimage:<VERSION>
    
    # Set correct environment variables.
    ENV HOME /root

    # Remove authentication rights for insecure_key.
    RUN rm -f /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys
    
    # Use baseimage-docker's init process.
    CMD ["/sbin/my_init"]
    
    # ...put other build instructions here...
    
    # Clean up APT when done.
    RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

### Adding additional daemons

You can add additional daemons to the image by creating runit entries. You only have to write a small shell script which runs your daemon, and runit will keep it up and running for you, restarting it when it crashes, etc.

The shell script must be called `run`, must be executable, and is to be placed in the directory `/etc/services/<NAME>`.

Here's an example showing you how to a memached server runit entry can be made.

    ### In memcached.sh (make sure this file is chmod +x):
    #!/bin/sh
    # `chpst` is part of running. `chpst -u memcache` runs the given command
    # as the user `memcache`. If you omit this, the command will be run as root.
    exec chpst -u memcache /usr/bin/memcached >>/var/log/memcached.log 2>&1

    ### In Dockerfile:
    RUN mkdir /etc/services/memcached
    ADD redis.sh /etc/services/memcached/run

Note that the shell script must run the daemon **without letting it daemonize/fork it**. Usually, daemons provide a command line flag or a config file option for that.

### Login in to the container

You can use SSH to login to any container that is based on baseimage-docker.

Start a container based on baseimage-docker (or a container based on an image based on baseimage-docker):

    docker run phusion/baseimage

Find out the ID of the container that you just ran:

    docker ps

Once you have the ID, look for its IP address with:

    docker inspect <ID> | grep IPAddress

Now SSH into the container. In this example we're using [the default insecure key](https://github.com/phusion/baseimage-docker/blob/master/image/insecure_key), but if you're followed the instructions well then you've already replaced that with your own key. You did replace the key, didn't you?

    ssh -i insecure_key root@<IP address>

## Building the image yourself

If for whatever reason you want to build the image yourself instead of downloading it from the Docker registry, follow these instructions.

Clone this repository:

    git clone https://github.com/phusion/baseimage-docker.git
    cd baseimage-docker

Start a virtual machine with Docker in it. You can use the Vagrantfile that we've already provided.

    vagrant up
    vagrant ssh
    cd /vagrant

Build the image:

    make build

If you want to call the resulting image something else, pass the NAME variable, like this:

    make build NAME=joe/baseimage

## Conclusion

 * Using baseimage-docker? [Tweet about us](https://twitter.com/share) or [follow us on Twitter](https://twitter.com/phusion_nl).
 * Having problems? Please post a message at [the discussion forum](https://groups.google.com/d/forum/passenger-docker).
 * Looking for a more complete base image, one that is ideal for Ruby, Python, Node.js and Meteor web apps? Take a look at [passenger-docker](https://github.com/phusion/passenger-docker).

[<img src="http://www.phusion.nl/assets/logo.png">](http://www.phusion.nl/)

Please enjoy baseimage-docker, a product by [Phusion](http://www.phusion.nl/). :-)
