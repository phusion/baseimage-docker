# A minimal Ubuntu base image modified for Docker-friendliness

[![](https://badge.imagelayers.io/phusion/baseimage:0.9.17.svg)](https://imagelayers.io/?images=phusion/baseimage:latest 'Get your own badge on imagelayers.io')

Baseimage-docker is a special [Docker](https://www.docker.com) image that is configured for correct use within Docker containers. It is Ubuntu, plus:

 * Modifications for Docker-friendliness.
 * Administration tools that are especially useful in the context of Docker.
 * Mechanisms for easily running multiple processes, [without violating the Docker philosophy](#docker_single_process).

You can use it as a base for your own Docker images.

Baseimage-docker is available for pulling from [the Docker registry](https://registry.hub.docker.com/u/phusion/baseimage/)!

### What are the problems with the stock Ubuntu base image?

Ubuntu is not designed to be run inside Docker. Its init system, Upstart, assumes that it's running on either real hardware or virtualized hardware, but not inside a Docker container. But inside a container you don't want a full system anyway, you want a minimal system. But configuring that minimal system for use within a container has many strange corner cases that are hard to get right if you are not intimately familiar with the Unix system model. This can cause a lot of strange problems.

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
   * [Does Baseimage-docker advocate "fat containers" or "treating containers as VMs"?](#fat_containers)
 * [Inspecting baseimage-docker](#inspecting)
 * [Using baseimage-docker as base image](#using)
   * [Getting started](#getting_started)
   * [Adding additional daemons](#adding_additional_daemons)
   * [Running scripts during container startup](#running_startup_scripts)
   * [Environment variables](#environment_variables)
     * [Centrally defining your own environment variables](#envvar_central_definition)
     * [Environment variable dumps](#envvar_dumps)
     * [Modifying environment variables](#modifying_envvars)
     * [Security](#envvar_security)
   * [Upgrading the operating system inside the container](#upgrading_os)
 * [Container administration](#container_administration)
   * [Running a one-shot command in a new container](#oneshot)
   * [Running a command in an existing, running container](#run_inside_existing_container)
   * [Login to the container via `docker exec`](#login_docker_exec)
     * [Usage](#docker_exec)
   * [Login to the container via SSH](#login_ssh)
     * [Enabling SSH](#enabling_ssh)
     * [About SSH keys](#ssh_keys)
     * [Using the insecure key for one container only](#using_the_insecure_key_for_one_container_only)
     * [Enabling the insecure key permanently](#enabling_the_insecure_key_permanently)
     * [Using your own key](#using_your_own_key)
     * [The `docker-ssh` tool](#docker_ssh)
 * [Building the image yourself](#building)
  * [Removing optional services](#removing_optional_services)
 * [Conclusion](#conclusion)

-----------------------------------------

<a name="whats_inside"></a>
## What's inside the image?

<a name="whats_inside_overview"></a>
### Overview

*Looking for a more complete base image, one that is ideal for Ruby, Python, Node.js and Meteor web apps? Take a look at [passenger-docker](https://github.com/phusion/passenger-docker).*

| Component        | Why is it included? / Remarks |
| ---------------- | ------------------- |
| Ubuntu 14.04 LTS | The base system. |
| A **correct** init process | _Main article: [Docker and the PID 1 zombie reaping problem](http://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)._ <br><br>According to the Unix process model, [the init process](https://en.wikipedia.org/wiki/Init) -- PID 1 -- inherits all [orphaned child processes](https://en.wikipedia.org/wiki/Orphan_process) and must [reap them](https://en.wikipedia.org/wiki/Wait_(system_call)). Most Docker containers do not have an init process that does this correctly, and as a result their containers become filled with [zombie processes](https://en.wikipedia.org/wiki/Zombie_process) over time. <br><br>Furthermore, `docker stop` sends SIGTERM to the init process, which is then supposed to stop all services. Unfortunately most init systems don't do this correctly within Docker since they're built for hardware shutdowns instead. This causes processes to be hard killed with SIGKILL, which doesn't give them a chance to correctly deinitialize things. This can cause file corruption. <br><br>Baseimage-docker comes with an init process `/sbin/my_init` that performs both of these tasks correctly. |
| Fixes APT incompatibilities with Docker | See https://github.com/dotcloud/docker/issues/1024. |
| syslog-ng | A syslog daemon is necessary so that many services - including the kernel itself - can correctly log to /var/log/syslog. If no syslog daemon is running, a lot of important messages are silently swallowed. <br><br>Only listens locally. All syslog messages are forwarded to "docker logs". |
| logrotate | Rotates and compresses logs on a regular basis. |
| SSH server | Allows you to easily login to your container to [inspect or administer](#login_ssh) things. <br><br>_SSH is **disabled by default** and is only one of the methods provided by baseimage-docker for this purpose. The other method is through [docker exec](#login_docker_exec). SSH is also provided as an alternative because `docker exec` comes with several caveats._<br><br>Password and challenge-response authentication are disabled by default. Only key authentication is allowed. |
| cron | The cron daemon must be running for cron jobs to work. |
| [runit](http://smarden.org/runit/) | Replaces Ubuntu's Upstart. Used for service supervision and management. Much easier to use than SysV init and supports restarting daemons when they crash. Much easier to use and more lightweight than Upstart. |
| `setuser` | A tool for running a command as another user. Easier to use than `su`, has a smaller attack vector than `sudo`, and unlike `chpst` this tool sets `$HOME` correctly. Available as `/sbin/setuser`. |

Baseimage-docker is very lightweight: it only consumes 6 MB of memory.

<a name="docker_single_process"></a>
### Wait, I thought Docker is about running a single process in a container?

The Docker developers advocate the philosophy of running a single *logical service* per container. A logical service can consist of multiple OS processes.

Baseimage-docker only advocates running multiple OS processes inside a single container. We believe this makes sense because at the very least it would solve [the PID 1 problem](http://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/) and the "syslog blackhole" problem. By running multiple processes, we solve very real Unix OS-level problems, with minimal overhead and without turning the container into multiple logical services.

Splitting your logical service into multiple OS processes also makes sense from a security standpoint. By running processes as different users, you can limit the impact of vulnerabilities. Baseimage-docker provides tools to encourage running processes as different users, e.g. the `setuser` tool.

Do we advocate running multiple *logical services* in a single container? Not necessarily, but we do not prohibit it either. While the Docker developers are very opinionated and have very rigid philosophies about how containers *should* be built, Baseimage-docker is completely unopinionated. We believe in freedom: sometimes it makes sense to run multiple services in a single container, and sometimes it doesn't. It is up to you to decide what makes sense, not the Docker developers.

<a name="fat_containers"></a>
### Does Baseimage-docker advocate "fat containers" or "treating containers as VMs"?

There are people who are under the impression that Baseimage-docker advocates treating containers as VMs, because of the fact that Baseimage-docker advocates the use of multiple processes. Therefore they are also under the impression that Baseimage-docker does not follow the Docker philosophy. Neither of these impressions are true.

The Docker developers advocate running a single *logical service* inside a single container. But we are not disputing that. Baseimage-docker advocates running multiple *OS processes* inside a single container, and a single logical service can consist of multiple OS processes.

It follows from this that Baseimage-docker also does not deny the Docker philosophy. In fact, many of the modifications we introduce are explicitly in line with the Docker philosophy. For example, using environment variables to pass parameters to containers is very much the "Docker way", and provide [a mechanism to easily work with environment variables](#environment_variables) in the presence of multiple processes that may run as different users.

<a name="inspecting"></a>
## Inspecting baseimage-docker

To look around in the image, run:

    docker run --rm -t -i phusion/baseimage:<VERSION> /sbin/my_init -- bash -l

where `<VERSION>` is [one of the baseimage-docker version numbers](https://github.com/phusion/baseimage-docker/blob/master/Changelog.md).

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

    # Use baseimage-docker's init system.
    CMD ["/sbin/my_init"]

    # ...put your own build instructions here...

    # Clean up APT when done.
    RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

<a name="adding_additional_daemons"></a>
### Adding additional daemons

You can add additional daemons (e.g. your own app) to the image by creating runit entries. You only have to write a small shell script which runs your daemon, and runit will keep it up and running for you, restarting it when it crashes, etc.

The shell script must be called `run`, must be executable, and is to be placed in the directory `/etc/service/<NAME>`.

Here's an example showing you how a memcached server runit entry can be made.

In `memcached.sh` (make sure this file is chmod +x):

    #!/bin/sh
    # `/sbin/setuser memcache` runs the given command as the user `memcache`.
    # If you omit that part, the command will be run as root.
    exec /sbin/setuser memcache /usr/bin/memcached >>/var/log/memcached.log 2>&1

In `Dockerfile`:

    RUN mkdir /etc/service/memcached
    ADD memcached.sh /etc/service/memcached/run

Note that the shell script must run the daemon **without letting it daemonize/fork it**. Usually, daemons provide a command line flag or a config file option for that.

<a name="running_startup_scripts"></a>
### Running scripts during container startup

The baseimage-docker init system, `/sbin/my_init`, runs the following scripts during startup, in the following order:

 * All executable scripts in `/etc/my_init.d`, if this directory exists. The scripts are run in lexicographic order.
 * The script `/etc/rc.local`, if this file exists.

All scripts must exit correctly, e.g. with exit code 0. If any script exits with a non-zero exit code, the booting will fail.

The following example shows how you can add a startup script. This script simply logs the time of boot to the file /tmp/boottime.txt.

In `logtime.sh` (make sure this file is chmod +x):

    #!/bin/sh
    date > /tmp/boottime.txt

In `Dockerfile`:

    RUN mkdir -p /etc/my_init.d
    ADD logtime.sh /etc/my_init.d/logtime.sh

<a name="environment_variables"></a>
### Environment variables

If you use `/sbin/my_init` as the main container command, then any environment variables set with `docker run --env` or with the `ENV` command in the Dockerfile, will be picked up by `my_init`. These variables will also be passed to all child processes, including `/etc/my_init.d` startup scripts, Runit and Runit-managed services. There are however a few caveats you should be aware of:

 * Environment variables on Unix are inherited on a per-process basis. This means that it is generally not possible for a child process to change the environment variables of other processes.
 * Because of the aforementioned point, there is no good central place for defining environment variables for all applications and services. Debian has the `/etc/environment` file but it only works in some situations.
 * Some services change environment variables for child processes. Nginx is one such example: it removes all environment variables unless you explicitly instruct it to retain them through the `env` configuration option. If you host any applications on Nginx (e.g. using the [passenger-docker](https://github.com/phusion/passenger-docker) image, or using Phusion Passenger in your own image) then they will not see the environment variables that were originally passed by Docker.

`my_init` provides a solution for all these caveats.

<a name="envvar_central_definition"></a>
#### Centrally defining your own environment variables

During startup, before running any [startup scripts](#running_startup_scripts), `my_init` imports environment variables from the directory `/etc/container_environment`. This directory contains files who are named after the environment variable names. The file contents contain the environment variable values. This directory is therefore a good place to centrally define your own environment variables, which will be inherited by all startup scripts and Runit services.

For example, here's how you can define an environment variable from your Dockerfile:

    RUN echo Apachai Hopachai > /etc/container_environment/MY_NAME

You can verify that it works, as follows:

    $ docker run -t -i <YOUR_NAME_IMAGE> /sbin/my_init -- bash -l
    ...
    *** Running bash -l...
    # echo $MY_NAME
    Apachai Hopachai

**Handling newlines**

If you've looked carefully, you'll notice that the 'echo' command actually prints a newline. Why does $MY_NAME not contain a newline then? It's because `my_init` strips the trailing newline, if any. If you intended on the value having a newline, you should add *another* newline, like this:

    RUN echo -e "Apachai Hopachai\n" > /etc/container_environment/MY_NAME

<a name="envvar_dumps"></a>
#### Environment variable dumps

While the previously mentioned mechanism is good for centrally defining environment variables, it by itself does not prevent services (e.g. Nginx) from changing and resetting environment variables from child processes. However, the `my_init` mechanism does make it easy for you to query what the original environment variables are.

During startup, right after importing environment variables from `/etc/container_environment`, `my_init` will dump all its environment variables (that is, all variables imported from `container_environment`, as well as all variables it picked up from `docker run --env`) to the following locations, in the following formats:

 * `/etc/container_environment`
 * `/etc/container_environment.sh` - a dump of the environment variables in Bash format. You can source the file directly from a Bash shell script.
 * `/etc/container_environment.json` - a dump of the environment variables in JSON format.

The multiple formats makes it easy for you to query the original environment variables no matter which language your scripts/apps are written in.

Here is an example shell session showing you how the dumps look like:

    $ docker run -t -i \
      --env FOO=bar --env HELLO='my beautiful world' \
      phusion/baseimage:<VERSION> /sbin/my_init -- \
      bash -l
    ...
    *** Running bash -l...
    # ls /etc/container_environment
    FOO  HELLO  HOME  HOSTNAME  PATH  TERM  container
    # cat /etc/container_environment/HELLO; echo
    my beautiful world
    # cat /etc/container_environment.json; echo
    {"TERM": "xterm", "container": "lxc", "HOSTNAME": "f45449f06950", "HOME": "/root", "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", "FOO": "bar", "HELLO": "my beautiful world"}
    # source /etc/container_environment.sh
    # echo $HELLO
    my beautiful world

<a name="modifying_envvars"></a>
#### Modifying environment variables

It is even possible to modify the environment variables in `my_init` (and therefore the environment variables in all child processes that are spawned after that point in time), by altering the files in `/etc/container_environment`. After each time `my_init` runs a [startup script](#running_startup_scripts), it resets its own environment variables to the state in `/etc/container_environment`, and re-dumps the new environment variables to `container_environment.sh` and `container_environment.json`.

But note that:

 * modifying `container_environment.sh` and `container_environment.json` has no effect.
 * Runit services cannot modify the environment like that. `my_init` only activates changes in `/etc/container_environment` when running startup scripts.

<a name="envvar_security"></a>
#### Security

Because environment variables can potentially contain sensitive information, `/etc/container_environment` and its Bash and JSON dumps are by default owned by root, and accessible only by the `docker_env` group (so that any user added this group will have these variables automatically loaded).

If you are sure that your environment variables don't contain sensitive data, then you can also relax the permissions on that directory and those files by making them world-readable:

    RUN chmod 755 /etc/container_environment
    RUN chmod 644 /etc/container_environment.sh /etc/container_environment.json

<a name="upgrading_os"></a>
### Upgrading the operating system inside the container

Baseimage-docker images contain an Ubuntu 14.04 operating system. You may want to update this OS from time to time, for example to pull in the latest security updates. OpenSSL is a notorious example. Vulnerabilities are discovered in OpenSSL on a regular basis, so you should keep OpenSSL up-to-date as much as you can.

While we release Baseimage-docker images with the latest OS updates from time to time, you do not have to rely on us. You can update the OS inside Baseimage-docker images yourself, and it is recommend that you do this instead of waiting for us.

To upgrade the OS in the image, run this in your Dockerfile:

    RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"

<a name="container_administration"></a>
## Container administration

One of the ideas behind Docker is that containers should be stateless, easily restartable, and behave like a black box. However, you may occasionally encounter situations where you want to login to a container, or to run a command inside a container, for development, inspection and debugging purposes. This section describes how you can administer the container for those purposes.

<a name="oneshot"></a>
### Running a one-shot command in a new container

_**Note:** This section describes how to run a command insider a -new- container. To run a command inside an existing running container, see [Running a command in an existing, running container](#run_inside_existing_container)._

Normally, when you want to create a new container in order to run a single command inside it, and immediately exit after the command exits, you invoke Docker like this:

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

<a name="run_inside_existing_container"></a>
### Running a command in an existing, running container

There are two ways to run a command inside an existing, running container.

 * Through the `docker exec` tool. This is builtin Docker tool, available since Docker 1.4. Internally, it uses Linux kernel system calls in order to execute a command within the context of a container. Learn more in [Login to the container, or running a command inside it, via `docker exec`](#login_docker_exec).
 * Through SSH. This approach requires running an SSH daemon inside the container, and requires you to setup SSH keys. Learn more in [Login to the container, or running a command inside it, via SSH](#login_ssh).

Both way have their own pros and cons, which you can learn in their respective subsections.

<a name="login_docker_exec"></a>
### Login to the container, or running a command inside it, via `docker exec`

You can use the `docker exec` tool on the Docker host OS to login to any container that is based on baseimage-docker. You can also use it to run a command inside a running container. `docker exec` works by using Linux kernel system calls.

Here's how it compares to [using SSH to login to the container or to run a command inside it](#login_ssh):

 * Pros
   * Does not require running an SSH daemon inside the container.
   * Does not require setting up SSH keys.
   * Works on any container, even containers not based on baseimage-docker.
 * Cons
   * If the `docker exec` process on the host is terminated by a signal (e.g. with the `kill` command or even with Ctrl-C), then the command that is executed by `docker exec` is *not* killed and cleaned up. You will either have to do that manually, or you have to run `docker exec` with `-t -i`.
   * Requires privileges on the Docker host to be able to access the Docker daemon. Note that anybody who can access the Docker daemon effectively has root access.
   * Not possible to allow users to login to the container without also letting them login to the Docker host.

<a name="docker_exec_usage"></a>
#### Usage

Start a container:

    docker run YOUR_IMAGE

Find out the ID of the container that you just ran:

    docker ps

Now that you have the ID, you can use `docker exec` to run arbitrary commands in the container. For example, to run `echo hello world`:

    docker exec YOUR-CONTAINER-ID echo hello world

To open a bash session inside the container, you must pass `-t -i` so that a terminal is available:

    docker exec -t -i YOUR-CONTAINER-ID bash -l

<a name="login_ssh"></a>
### Login to the container, or running a command inside it, via SSH

You can use SSH to login to any container that is based on baseimage-docker. You can also use it to run a command inside a running container.

Here's how it compares to [using `docker exec` to login to the container or to run a command inside it](#login_docker_exec):

 * Pros
   * Does not require root privileges on the Docker host.
   * Allows you to let users login to the container, without letting them login to the Docker host. However, this is not enabled by default because baseimage-docker does not expose the SSH server to the public Internet by default.
 * Cons
   * Requires setting up SSH keys. However, baseimage-docker makes this easy for many cases through a pregenerated, insecure key. Read on to learn more.

<a name="enabling_ssh"></a>
#### Enabling SSH

Baseimage-docker disables the SSH server by default. Add the following to your Dockerfile to enable it:

    RUN rm -f /etc/service/sshd/down

    # Regenerate SSH host keys. baseimage-docker does not contain any, so you
    # have to do that yourself. You may also comment out this instruction; the
    # init system will auto-generate one during boot.
    RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

<a name="ssh_keys"></a>
#### About SSH keys

First, you must ensure that you have the right SSH keys installed inside the container. By default, no keys are installed, so nobody can login. For convenience reasons, we provide [a pregenerated, insecure key](https://github.com/phusion/baseimage-docker/blob/master/image/services/sshd/keys/insecure_key) [(PuTTY format)](https://github.com/phusion/baseimage-docker/blob/master/image/services/sshd/keys/insecure_key.ppk) that you can easily enable. However, please be aware that using this key is for convenience only. It does not provide any security because this key (both the public and the private side) is publicly available. **In production environments, you should use your own keys**.

<a name="using_the_insecure_key_for_one_container_only"></a>
#### Using the insecure key for one container only

You can temporarily enable the insecure key for one container only. This means that the insecure key is installed at container boot. If you `docker stop` and `docker start` the container, the insecure key will still be there, but if you use `docker run` to start a new container then that container will not contain the insecure key.

Start a container with `--enable-insecure-key`:

    docker run YOUR_IMAGE /sbin/my_init --enable-insecure-key

Find out the ID of the container that you just ran:

    docker ps

Once you have the ID, look for its IP address with:

    docker inspect -f "{{ .NetworkSettings.IPAddress }}" <ID>

Now that you have the IP address, you can use SSH to login to the container, or to execute a command inside it:

    # Download the insecure private key
    curl -o insecure_key -fSL https://github.com/phusion/baseimage-docker/raw/master/image/services/sshd/keys/insecure_key
    chmod 600 insecure_key

    # Login to the container
    ssh -i insecure_key root@<IP address>

    # Running a command inside the container
    ssh -i insecure_key root@<IP address> echo hello world

<a name="enabling_the_insecure_key_permanently"></a>
#### Enabling the insecure key permanently

It is also possible to enable the insecure key in the image permanently. This is not generally recommended, but is suitable for e.g. temporary development or demo environments where security does not matter.

Edit your Dockerfile to install the insecure key permanently:

    RUN /usr/sbin/enable_insecure_key

Instructions for logging in the container is the same as in section [Using the insecure key for one container only](#using_the_insecure_key_for_one_container_only).

<a name="using_your_own_key"></a>
#### Using your own key

Edit your Dockerfile to install an SSH public key:

    ## Install an SSH of your choice.
    ADD your_key.pub /tmp/your_key.pub
    RUN cat /tmp/your_key.pub >> /root/.ssh/authorized_keys && rm -f /tmp/your_key.pub

Then rebuild your image. Once you have that, start a container based on that image:

    docker run your-image-name

Find out the ID of the container that you just ran:

    docker ps

Once you have the ID, look for its IP address with:

    docker inspect -f "{{ .NetworkSettings.IPAddress }}" <ID>

Now that you have the IP address, you can use SSH to login to the container, or to execute a command inside it:

    # Login to the container
    ssh -i /path-to/your_key root@<IP address>

    # Running a command inside the container
    ssh -i /path-to/your_key root@<IP address> echo hello world

<a name="docker_ssh"></a>
#### The `docker-ssh` tool

Looking up the IP of a container and running an SSH command quickly becomes tedious. Luckily, we provide the `docker-ssh` tool which automates this process. This tool is to be run on the *Docker host*, not inside a Docker container.

First, install the tool on the Docker host:

    curl --fail -L -O https://github.com/phusion/baseimage-docker/archive/master.tar.gz && \
    tar xzf master.tar.gz && \
    sudo ./baseimage-docker-master/install-tools.sh

Then run the tool as follows to login to a container using SSH:

    docker-ssh YOUR-CONTAINER-ID

You can lookup `YOUR-CONTAINER-ID` by running `docker ps`.

By default, `docker-ssh` will open a Bash session. You can also tell it to run a command, and then exit:

    docker-ssh YOUR-CONTAINER-ID echo hello world


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

<a name="removing_optional_services"></a>
### Removing optional services

The default baseimage-docker installs `syslog-ng`, `cron` and `sshd` services during the build process.

In case you don't need one or more of these services in your image, you can disable its installation.

As shown in the following example, to prevent `sshd` from being installed into your image, set `1` to the `DISABLE_SSH` variable in the `./image/buildconfig` file.

    ### In ./image/buildconfig
    # ...
    # Default services
    # Set 1 to the service you want to disable
    export DISABLE_SYSLOG=0
    export DISABLE_SSH=1
    export DISABLE_CRON=0

Then you can proceed with `make build` command.

<a name="conclusion"></a>
## Conclusion

 * Using baseimage-docker? [Tweet about us](https://twitter.com/share) or [follow us on Twitter](https://twitter.com/phusion_nl).
 * Having problems? Want to participate in development? Please post a message at [the discussion forum](https://groups.google.com/d/forum/passenger-docker).
 * Looking for a more complete base image, one that is ideal for Ruby, Python, Node.js and Meteor web apps? Take a look at [passenger-docker](https://github.com/phusion/passenger-docker).

[<img src="http://www.phusion.nl/assets/logo.png">](http://www.phusion.nl/)

Please enjoy baseimage-docker, a product by [Phusion](http://www.phusion.nl/). :-)
