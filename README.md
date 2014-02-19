# A minimal Ubuntu base image modified for Docker-friendliness

Baseimage-docker is a special [Docker](http://www.docker.io) image that is configured for correct use within Docker containers. It is Ubuntu, plus modifications for Docker-friendliness. You can use it as a base for your own Docker images.

Baseimage-docker is available for pulling from [the Docker registry](https://index.docker.io/u/phusion/baseimage/)!

### What are the problems with the stock Ubuntu base image?

Ubuntu is not designed to be run inside docker. Its init system, Upstart, assumes that it's running on either real hardware or virtualized hardware, but not inside a Docker container. But inside a container you don't want a full system anyway, you want a minimal system. But configuring that minimal system for use within a container has many strange corner cases that are hard to get right if you are not intimately familiar with the Unix system model. This can cause a lot of strange problems.

Baseimage-docker gets everything right. The "Contents" section describes all the things that it modifies.

<a name="why_use"></a>
### Why use baseimage-docker?

You can configure the stock `ubuntu` image yourself from your Dockerfile, so why bother using baseimage-docker?

 * Configuring the base system for Docker-friendliness is no easy task. As stated before, there are many corner cases. By the time that you've gotten all that right, you've reinvented baseimage-docker. Using baseimage-docker will save you from this effort.
 * It reduces the time needed to write a correct Dockerfile. You won't have to worry about the base system and can focus on your stack and your app.
 * It reduces the time needed to run `docker build`, allowing you to iterate your Dockerfile more quickly.
 * It reduces download time during redeploys. Docker only needs to download the base image once: during the first deploy. On every subsequent deploys, only the changes you make on top of the base image are downloaded.

-----------------------------------------

**Related resources**:
  [Website](http://phusion.github.io/baseimage-docker/) |
  [Github](https://github.com/phusion/baseimage-docker) |
  [Docker registry](https://index.docker.io/u/phusion/baseimage/) |
  [Discussion forum](https://groups.google.com/d/forum/passenger-docker) |
  [Twitter](https://twitter.com/phusion_nl) |
  [Blog](http://blog.phusion.nl/)

**Table of contents**

 * [What's inside the image?](#whats_inside)
   * [Overview](#whats_inside_overview)
   * [Wait, I thought Docker is about running a single process in a container?](#docker_single_process)
 * [Inspecting baseimage-docker](#inspecting)
 * [Using baseimage-docker as base image](#using)
   * [Getting started](#getting_started)
   * [Adding additional daemons](#adding_additional_daemons)
   * [Running scripts during container startup](#running_startup_scripts)
   * [Running a one-shot command in the container](#oneshot)
   * [Login to the container via SSH](#login)
 * [Building the image yourself](#building)
 * [Conclusion](#conclusion)

-----------------------------------------

<a name="whats_inside"></a>
## What's inside the image?

<a name="whats_inside_overview"></a>
### Overview

*Looking for a more complete base image, one that is ideal for Ruby, Python, Node.js and Meteor web apps? Take a look at [passenger-docker](https://github.com/phusion/passenger-docker).*

| Component        | Why is it included? / Remarks |
| ---------------- | ------------------- |
| Ubuntu 12.04 LTS | The base system. |
| A **correct** init process | According to the Unix process model, [the init process](https://en.wikipedia.org/wiki/Init) -- PID 1 -- inherits all [orphaned child processes](https://en.wikipedia.org/wiki/Orphan_process) and must [reap them](https://en.wikipedia.org/wiki/Wait_(system_call)). Most Docker containers do not have an init process that does this correctly, and as a result their containers become filled with [zombie processes](https://en.wikipedia.org/wiki/Zombie_process) over time. <br><br>Furthermore, `docker stop` sends SIGTERM to the init process, which is then supposed to stop all services. Unfortunately most init systems don't do this correctly within Docker since they're built for hardware shutdowns instead. This causes processes to be hard killed with SIGKILL, which doesn't give them a chance to correctly deinitialize things. This can cause file corruption. <br><br>Baseimage-docker comes with an init process `/sbin/my_init` that performs both of these tasks correctly. |
| Fixes APT incompatibilities with Docker | See https://github.com/dotcloud/docker/issues/1024. |
| syslog-ng | A syslog daemon is necessary so that many services - including the kernel itself - can correctly log to /var/log/syslog. If no syslog daemon is running, a lot of important messages are silently swallowed. <br><br>Only listens locally. |
| ssh server | Allows you to easily login to your container to inspect or administer things. <br><br>Password and challenge-response authentication are disabled by default. Only key authentication is allowed.<br>By default, it allows a predefined key, in order to make debugging easy. You should replace this ASAP. See instructions. |
| cron | The cron daemon must be running for cron jobs to work. |
| [runit](http://smarden.org/runit/) | Replaces Ubuntu's Upstart. Used for service supervision and management. Much easier to use than SysV init and supports restarting daemons when they crash. Much easier to use and more lightweight than Upstart. |
| `setuser` | A tool for running a command as another user. Easier to use than `su`, has a smaller attack vector than `sudo`, and unlike `chpst` this tool sets `$HOME` correctly. Available as `/sbin/setuser`. |

Baseimage-docker is very lightweight: it only consumes 6 MB of memory.

<a name="docker_single_process"></a>
### Wait, I thought Docker is about running a single process in a container?

Absolutely not true. Docker runs fine with multiple processes in a container. In fact, there is no technical reason why you should limit yourself to one process - it only makes things harder for you and breaks all kinds of essential system functionality, e.g. syslog.

Baseimage-docker *encourages* multiple processes through the use of runit.

<a name="inspecting"></a>
## Inspecting baseimage-docker

To look around in the image, run:

    docker run -rm -t -i phusion/baseimage bash -l

You don't have to download anything manually. The above command will automatically pull the baseimage-docker image from the Docker registry.

<a name="using"></a>
## Using baseimage-docker as base image

<a name="getting_started"></a>
### Getting started

The image is called `phusion/baseimage`, and is available on the Docker registry.

    # Use phusion/baseimage as base image. To make your builds reproducible, make
    # sure you lock down to a specific version, not to `latest`!
    # See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
    # a list of version numbers.
    FROM phusion/baseimage:<VERSION>
    
    # Set correct environment variables.
    ENV HOME /root
    
    # Regenerate SSH host keys. baseimage-docker does not contain any, so you
    # have to do that yourself. You may also comment out this instruction; the
    # init system will auto-generate one during boot.
    RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
    
    # Use baseimage-docker's init system.
    CMD ["/sbin/my_init"]
    
    # ...put your own build instructions here...
    
    # Clean up APT when done.
    RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

<a name="adding_additional_daemons"></a>
### Adding additional daemons

You can add additional daemons (e.g. your own app) to the image by creating runit entries. You only have to write a small shell script which runs your daemon, and runit will keep it up and running for you, restarting it when it crashes, etc.

The shell script must be called `run`, must be executable, and is to be placed in the directory `/etc/service/<NAME>`.

Here's an example showing you how to a memached server runit entry can be made.

    ### In memcached.sh (make sure this file is chmod +x):
    #!/bin/sh
    # `/sbin/setuser memcache` runs the given command as the user `memcache`.
    # If you omit that part, the command will be run as root.
    exec /sbin/setuser memcache /usr/bin/memcached >>/var/log/memcached.log 2>&1

    ### In Dockerfile:
    RUN mkdir /etc/service/memcached
    ADD memcached.sh /etc/service/memcached/run

Note that the shell script must run the daemon **without letting it daemonize/fork it**. Usually, daemons provide a command line flag or a config file option for that.

<a name="running_startup_scripts"></a>
### Running scripts during container startup

The baseimage-docker init system, `/sbin/my_init`, runs the following scripts during startup, in the following order:

 * All executable scripts in `/etc/my_init.d`, if this directory exists. The scripts are run during in lexicographic order.
 * The script `/etc/rc.local`, if this file exists.

All scripts must exit correctly, e.g. with exit code 0. If any script exits with a non-zero exit code, the booting will fail.

The following example shows how you can add a startup script. This script simply logs the time of boot to the file /tmp/boottime.txt.

    ### In logtime.sh (make sure this file is chmod +x):
    #!/bin/sh
    date > /tmp/boottime.txt

    ### In Dockerfile:
    RUN mkdir -p /etc/my_init.d
    ADD logtime.sh /etc/my_init.d/logtime.sh

<a name="oneshot"></a>
### Running a one-shot command in the container

Normally, when you want to run a single command in a container, and exit immediately after the command, you invoke Docker like this:

    docker run YOUR_IMAGE COMMAND ARGUMENTS...

However the downside of this approach is that the init system is not started. That is, while invoking `COMMAND`, important daemons such as cron and syslog are not running. Also, orphaned child processes are not properly reaped, because `COMMAND` is PID 1.

Baseimage-docker provides a facility to run a single one-shot command, while solving all of the aforementioned problems. Run a single command in the following manner:

    docker run YOUR_IMAGE /sbin/my_init -- COMMAND ARGUMENTS ...

This will perform the following:

 * Runs all system startup files, such as /etc/my_init.d/* and /etc/rc.local.
 * Starts all runit services.
 * Runs the specified command.
 * When the specified command exits, stops all runit services.

For example:

    $ docker run phusion/baseimage:<VERSION> /sbin/my_init -- ls
    *** Running /etc/my_init.d/00_regen_ssh_host_keys.sh...
    No SSH host key available. Generating one...
    Creating SSH2 RSA key; this may take some time ...
    Creating SSH2 DSA key; this may take some time ...
    Creating SSH2 ECDSA key; this may take some time ...
    *** Running /etc/rc.local...
    *** Booting runit daemon...
    *** Runit started as PID 80
    *** Running ls...
    bin  boot  dev  etc  home  image  lib  lib64  media  mnt  opt  proc  root  run  sbin  selinux  srv  sys  tmp  usr  var
    *** ls exited with exit code 0.
    *** Shutting down runit daemon (PID 80)...
    *** Killing all processes...

You may find that the default invocation is too noisy. Or perhaps you don't want to run the startup files. You can customize all this by passing arguments to `my_init`. Invoke `docker run YOUR_IMAGE /sbin/my_init --help` for more information.

The following example runs `ls` without running the startup files and with less messages, while running all runit services:

    $ docker run phusion/baseimage:<VERSION> /sbin/my_init --skip-startup-files --quiet -- ls
    bin  boot  dev  etc  home  image  lib  lib64  media  mnt  opt  proc  root  run  sbin  selinux  srv  sys  tmp  usr  var

<a name="login"></a>
### Login to the container via SSH

You can use SSH to login to any container that is based on baseimage-docker.

The first thing that you need to do is to ensure that you have the right SSH keys installed inside the container. By default, no keys are installed, so you can't login. For convenience reasons, we provide [a pregenerated, insecure key](https://github.com/phusion/baseimage-docker/blob/master/image/insecure_key) that you easily enable. However, please be aware that using this key is for convenience only. It does not provide any security because this key (both the public and the private side) is publicly available. In production environments, you should use your own keys.

Edit your Dockerfile to install an SSH key:

    ## Install an SSH of your choice.
    ADD your_key /tmp/your_key
    RUN cat /tmp/your_key >> /root/.ssh/authorized_keys && rm -f /tmp/your_key

    ## -OR-

    ## Uncomment this to enable the insecure key.
    # RUN /usr/sbin/enable_insecure_key

Then rebuild your image. Once you have that, start a container based on that image:

    docker run your-image-name

Find out the ID of the container that you just ran:

    docker ps

Once you have the ID, look for its IP address with:

    docker inspect <ID> | grep IPAddress

Now SSH into the container as follows:

    ssh -i /path-to/your_key root@<IP address>

    # -OR-

    # If you're using the insecure key, download it and SSH
    # into the container using that key.
    curl -o insecure_key -fSL https://github.com/phusion/baseimage-docker/raw/master/image/insecure_key
    chmod 700 insecure_key
    ssh -i insecure_key root@<IP address>

<a name="building"></a>
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

<a name="conclusion"></a>
## Conclusion

 * Using baseimage-docker? [Tweet about us](https://twitter.com/share) or [follow us on Twitter](https://twitter.com/phusion_nl).
 * Having problems? Want to participate in development? Please post a message at [the discussion forum](https://groups.google.com/d/forum/passenger-docker).
 * Looking for a more complete base image, one that is ideal for Ruby, Python, Node.js and Meteor web apps? Take a look at [passenger-docker](https://github.com/phusion/passenger-docker).

[<img src="http://www.phusion.nl/assets/logo.png">](http://www.phusion.nl/)

Please enjoy baseimage-docker, a product by [Phusion](http://www.phusion.nl/). :-)
