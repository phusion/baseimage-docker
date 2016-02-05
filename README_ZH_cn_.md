<a name="a-minimal-ubuntu-base-image-modified-for-docker-friendliness"></a>
# Docker友好的，最小的Ubuntu基础镜像

Baseimage-docker是一个特殊的[Docker](http://www.docker.io)镜像，在Docker容器内做了配置，并且可以正确使用。它确实是一个Ubuntu系统, 除此之外进行了如下修订：

 * 为更加友好的支持Docker，做了修订。
 * 在Docker环境下，作为管理工具特别有用。
 * 在[不违反Docker哲学](#docker_single_process)的前提下，能够很容易的运行多进程的机制。

可以把它作为自己的基础Docker镜像。

Baseimage-docker项目可以直接从Docker的[registry](https://index.docker.io/u/phusion/baseimage/)获取！
        
<a name="what-are-the-problems-with-the-stock-ubuntu-base-image"></a>
### 原生的Ubuntu基础镜像有什么问题呢？          
            
原生Ubuntu不是为了在Docker内运行而设计的。它的初始化系统Upstart，假定运行的环境要么是真实的硬件，要么是虚拟的硬件，而不是在Docker容器内。但是在一个Docker的容器内，并不需要一个完整的系统，你需要的只是一个很小的系统。但是如果你不是非常熟悉Unix的系统模型，想要在Docker容器内裁减出最小的系统，会碰到很多难以正确解决的陌生的技术坑。这些坑会引起很多莫名其妙的问题。

Baseimage-docker让这一切完美。在"内容"部分描述了所有这些修改。

<a name="why-use-baseimage-docker"></a>
### 为什么使用baseimage-docker？

你自己可以从Dockerfile配置一个原生`ubuntu`镜像，为什么还要多此一举的使用baseimage-docker呢?
        
 * 配置一个Docker友好的基础系统并不是一个简单的任务。如前所述，过程中会碰到很多坑。当你搞定这些坑之后，只不过是又重新发明了一个baseimage-docker而已。使用baseimage-docker可以免去你这方面需要做的努力。          
 * 减少需要正确编写Dockerfile文件的时间。你不用再担心基础系统，可以专注于你自己的技术栈和你的项目。            
 * 减少需要运行`docker build`的时间，让你更快的迭代Dockerfile。         
 * 减少了重新部署的时的下载时间。Docker只需要在第一次部署的时候下载一次基础镜像。在随后的部署中,只需要改变你下载之后对基础镜像进行修改的部分。

-----------------------------------------

**相关资源**

  [网站](http://phusion.github.io/baseimage-docker/) |
  [Github](https://github.com/phusion/baseimage-docker) |
  [Docker registry](https://index.docker.io/u/phusion/baseimage/) |
  [论坛](https://groups.google.com/d/forum/passenger-docker) |
  [Twitter](https://twitter.com/phusion_nl) |
  [Blog](http://blog.phusion.nl/)

**目录**

 * [镜像里面有什么?](#whats_inside)
   * [概述](#whats_inside_overview)
   * [等等,我认为Docker在一个容器中只能允许运行一个进程?](#docker_single_process)           
   * [Baseimage-docker更侧重于“胖容器”还是“把容器当作虚拟机”？](#fat_containers)            
 * [查看baseimage-docker](#inspecting)
 * [使用baseimage-docker作为基础镜像](#using)
   * [开始](#getting_started)
   * [增加额外的后台进程](#adding_additional_daemons)
   * [容器启动时运行脚本](#running_startup_scripts)
   * [环境变量](#environment_variables)
     * [集中定义自己的环境变量](#envvar_central_definition)
     * [保存环境变量](#envvar_dumps)
     * [修改环境变量](#modifying_envvars)
     * [安全性](#envvar_security)
 * [容器管理](#container_administration)
   * [在一个新容器中运行单条命令](#oneshot)
   * [在正在运行的的容器中运行一条命令](#run_inside_existing_container)
   * [通过`docer exec`登录容器](#login_docker_exec)
     * [用法](#nsenter_usage)
   * [使用SSH登录容器](#login_ssh)
     * [启用SSH](#enabling_ssh)
     * [关于SSH的key](#ssh_keys)
     * [只对一个容器使用不安全key](#using_insecure_key_for_one_container_only)
     * [永久开启不安全key](#enabling_the_insecure_key_permanently)
     * [使用你自己的key](#using_your_own_key)
     * [`docker-ssh`工具](#docker_ssh)
 * [构建自己的镜像](#building)
 * [总结](#conclusion)

-----------------------------------------

<a name="whats_inside"></a>
## 镜像里面有什么？

<a name="whats_inside_overview"></a>
### 概述

*想看一个里面包含Ruby，Python，Node.js以及Meteor的完整基础镜像？可以看一下[passenger-docker](https://github.com/phusion/passenger-docker)。*            

| 模块        | 为什么包含这些？以及备注 |
| ---------------- | ------------------- |
| Ubuntu 14.04 LTS | 基础系统。 |
| 一个**正确**的初始化进程  | *主要文章：[Docker和PID 1 僵尸进程回收问题](http://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)*<br/><br/>根据Unix进程模型，[初始化进程](https://en.wikipedia.org/wiki/Init) -- PID 1 -- 继承了所有[孤立的子进程](https://en.wikipedia.org/wiki/Orphan_process)，并且必须[进行回收](https://en.wikipedia.org/wiki/Wait_(system_call))。大多数Docker容器没有一个初始化进程可以正确的完成此操作，随着时间的推移会导致他们的容器出现了大量的[僵尸进程](https://en.wikipedia.org/wiki/Zombie_process)。<br/><br/>而且，`docker stop`发送SIGTERM信号给初始化进程，照理说此信号应该可以停止所有服务。不幸的是由于它们对硬件进行了关闭操作，导致Docker内的大多数初始化系统没有正确执行。这会导致进程强行被SIGKILL信号关闭，从而丧失了一个正确取消初始化设置的机会。这会导致文件损坏。<br/><br/>Baseimage-docker配有一个名为`/sbin/my_init`的初始化进程来同时正确的完成这些任务。 |
| 修复了APT与Docker不兼容的问题 | 详情参见：https://github.com/dotcloud/docker/issues/1024 。 |
| syslog-ng | 对于很多服务－包括kernel自身，都需要一个syslog后台进程，以便可以正确的将log输出到/var/log/syslog中。如果没有运行syslog后台进程，很多重要的信息就会默默的丢失了。<br/><br/>只对本地进行监听。所有syslog信息会被转发给“docker logs”。 |
| logrotate | 定期转存和压缩日志。 |
| SSH服务 | 允许你很容易的登录到容器中进行[查询或管理](#login_ssh)操作。<br/><br/>_SSH**默认是禁用**的，这也是baseimage-docker为此目的提供的唯一方法。其它方法需要通过[docker exec](#login_docker_exec)。由于`docker exec`同时带来了几个需要注意的问题，SSH同时也提供了一个可替换的方法。_<br/><br/>密码和challenge-response认证方式默认是禁用的。只有key认证通过之后才能够开启。 |
| cron | 为了保证cron任务能够工作，必须运行cron后台进程。 |
| [runit](http://smarden.org/runit/) | 替换Ubuntu的Upstart。用于服务监控和管理。比SysV init更容易使用，同时当这些服务崩溃之后，支持后台进程自动重启。比Upstart更易使用，更加的轻量级。 |
| `setuser` | 使用其它账户运行命令的工具。比`su`更容易使用，比使用`sudo`有那么一点优势，跟`chpst`不同，这个工具需要正确的设置`$HOME`。像`/sbin/setuser`这样。 |
Baseimage-docker非常的轻量级：仅仅占用6MB内存。

<a name="docker_single_process"></a>
### 等等,我认为Docker在一个容器中就运行一个进程吗?
绝对不是这样的. 在一个docker容器中,运行多个进程也是很好的. 事实上,没有什么技术原因限制你只运行一个进程,运行很多的进程,只会把容器中系统的基本功能搞的更乱,比如syslog.

Baseimage-docker *鼓励* 通过runit来运行多进程.

<a name="inspecting"></a>
## 检测一下baseimage-docker

要检测镜像,执行下面的命令:

    docker run --rm -t -i phusion/baseimage:<VERSION> /sbin/my_init -- bash -l

`<VERSION>` 是[baseimage-docker的版本号](https://github.com/phusion/baseimage-docker/blob/master/Changelog.md).

你不用手动去下载任何文件.上面的命令会自动从docker仓库下载baseimage-docker镜像.

<a name="using"></a>
## 使用baseimage-docker作为基础镜像

<a name="getting_started"></a>
### 入门指南

镜像名字叫`phusion/baseimage`,在Docker仓库上也是可用的.

下面的这个是一个Dockerfile的模板.

	# 使用phusion/baseimage作为基础镜像,去构建你自己的镜像,需要下载一个明确的版本,千万不要使用`latest`.
	# 查看https://github.com/phusion/baseimage-docker/blob/master/Changelog.md,可用看到版本的列表.
	FROM phusion/baseimage:<VERSION>
	
	# 设置正确的环境变量.
	ENV HOME /root
	
	# 生成SSH keys,baseimage-docker不包含任何的key,所以需要你自己生成.你也可以注释掉这句命令,系统在启动过程中,会生成一个.
	RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
	
	# 初始化baseimage-docker系统
	CMD ["/sbin/my_init"]
	
	# 这里可以放置你自己需要构建的命令
	
	# 当完成后,清除APT.
	RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


<a name="adding_additional_daemons"></a>
### 增加后台进程

你可以通过runit工具向你的镜像中添加后台进程(例如:你自己的某些应用).你需要编写一个运行你需要的后台进程的脚步就可以了,runit工具会保证它的正常运行,如果进程死掉,runit也会重启它的.

脚本的名称必须是`run`,必须是可以运行的,它需要放到`/etc/service/<NAME>`.

这里有一个例子,向你展示如果运行memcached服务的.

	### memcached.sh(确定文件的权限是chmod +x):
	#!/bin/sh
	# `/sbin/setuser memcache` 指定一个`memcache`用户来运行命令.如果你忽略了这部分,就会使用root用户执行.
	exec /sbin/setuser memcache /usr/bin/memcached >>/var/log/memcached.log 2>&1
	
	### 在Dockerfile中:
    RUN mkdir /etc/service/memcached
    ADD memcached.sh /etc/service/memcached/run

注意脚本必须运行在后台的,**不能让他们进程进行daemonize/fork**.通常,后台进程会提供一个标志位或者配置文件.

<a name="running_startup_scripts"></a>
### 在容器启动的时候,运行脚本.

baseimage-docker的初始化脚本 `/sbin/my_init`,在启动的时候进程运行,按照下面的顺序:

 * 如果`/etc/my_init.d`存在,则按照字母顺序执行脚本.
 * 如果`/etc/rc.local`存在,则执行里面的脚本.

所有的脚本都是正确退出的,例如:退出的code是0.如果有任何脚本以非0的code退出,启动就会失败.

下面的例子向你展示了怎么添加一个启动脚本.这个脚本很简单的记录的一个系统启动时间,将启动时间记录到/tmp/boottime.txt.

    ### 在 logtime.sh (文件权限chmod +x):
    #!/bin/sh
    date > /tmp/boottime.txt

    ### 在 Dockerfile中:
    RUN mkdir -p /etc/my_init.d
    ADD logtime.sh /etc/my_init.d/logtime.sh


<a name="environment_variables"></a>
### 环境变量

如果你使用`/sbin/my_init`作为主容器命令,那么通过`docker run --env`或者在Dockerfile文件中设置的`ENV`环境变量,都会被`my_init`读取.

 * 在Unix系统中,环境变量都会被子进程给继承.这就意味着,子进程不可能修改环境变量或者修改其他进程的环境变量.
 * 由于上面提到的一点,这里没有一个可以为所有应用和服务集中定义环境的地方.Debian提供了一个`/etc/environment` 文件,解决一些问题.
 * 某些服务更改环境变量是为了给子进程使用.Nginx有这样的一个例子:它移除了所有的环境变量,除非你通过`env`进行了配置,明确了某些是保留的.如果你部署了任何应用在Nginx镜像(例如:使用[passenger-docker](https://github.com/phusion/passenger-docker)镜像或者使用Phusion Passenger作为你的镜像.),那么你通过Docker,你不会看到任何环境变量.
 

`my_init`提供了一个办法来解决这些问题.

<a name="envvar_central_definition"></a>
#### 集中定义你的环境变量

在启动的时候,在执行[startup scripts](#running_startup_scripts),`my_init`会从`/etc/container_environment`导入环境变量.这个文件夹下面,包含的文件,文件被命名为环境变量的名字.文件内容就是环境变量的值.这个文件夹是因此是一个集中定义你的环境变量的好地方,它会继承到所有启动项目和Runit管理的服务中.

给个例子,在你的dockerfile如何定义一个环境变量:

    RUN echo Apachai Hopachai > /etc/container_environment/MY_NAME

你可以按照下面这样验证:

    $ docker run -t -i <YOUR_NAME_IMAGE> /sbin/my_init -- bash -l
    ...
    *** Running bash -l...
    # echo $MY_NAME
    Apachai Hopachai

**换行处理**

如果你观察仔细一点,你会注意到'echo'命令,实际上在它是在新行打印出来的.为什么$MY_NAME没有包含在一行呢? 因为`my_init`在尾部有个换行字符.如果你打算让你的值包含一个新行,你需要增*另外*一个新字符,像这样:

    RUN echo -e "Apachai Hopachai\n" > /etc/container_environment/MY_NAME

<a name="envvar_dumps"></a>
#### 环境变量存储

上面提到集中定义环境变量,它不会从子服务进程改变父服务进程或者重置环境变量.而且,`my_init`也会很容易的让你查询到原始的环境变量是什么.

在启动的时候,`/etc/container_environment`, `my_init`中的变量会存储起来,并且导入到环境变量中,例如一下的格式:

 * `/etc/container_environment`
 * `/etc/container_environment.sh`- 一个bash存储的环境变量格式.你可以从这个命令中得到base格式的文件.
 * `/etc/container_environment.json` - 一个json格式存储的环境变量格式.

多种格式可以让你不管采用什么语言/apps都可以很容易使用环境变量.

这里有个例子,展示怎么使用:

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
#### 修改环境变量

通过修改`/etc/container_environment`这个文件,很有可能修改了`my_init`中的环境变量.之后,每次`my_init`启动[启动脚本](#running_startup_scripts),就会重置掉我们自己`/etc/container_environment`中的环境变量,也就会导致`container_environment.sh`和`container_environment.json`重新存储.

但是记住这些:

 * 修改`container_environment.sh` 和 `container_environment.json`是没有效果的.
 * Runit 的服务是不能像这样修改环境变量的.`my_init`运行的时候,只对`/etc/container_environment`中的修改是生效的.

<a name="envvar_security"></a>
#### 安全

因为环境变量可能包含敏感信息, `/etc/container_environment`和它的bash文件和JSON文件,默认都是root,都是可以被`docker_env`群组可以访问的(所以任何用户只要添加到群组中,都可以自动的获取这些信息).

如果你确定你的环境变量中没有什么敏感信息,那么你可以放松管理权限,将文件夹和文件分配下面的权限:

    RUN chmod 755 /etc/container_environment
    RUN chmod 644 /etc/container_environment.sh /etc/container_environment.json

<a name="workaroud_modifying_etc_hosts"></a>
### 解决Docker没有办法解决的/etc/hosts的问题

当前是没有办法在docker容器中修改`/etc/hosts`,这个是因为[Docker bug 2267](https://github.com/dotcloud/docker/issues/2267).Baseimage-docker包含了解决这个问题的办法,你必须明白是怎么修改的.

修改的办法包含在系统库中的` libnss_files.so.2`文件,这个文件使用`/etc/workaround-docker-2267/hosts`来代替系统使用`/etc/hosts`.如果需要修改`/etc/hosts`,你只要修改`/etc/workaround-docker-2267/hosts`就可以了.

增加这个修改到你的Dockerfile.下面的命令修改了文件`libnss_files.so.2`.

    RUN /usr/bin/workaround-docker-2267

(其实你不用在Dockerfile文件中运行这个命令,你可以在容器中运行一个shell就可以了.)

验证一下它是否生效了,[在你的容器中打开一个shell](#inspecting),修改`/etc/workaround-docker-2267/hosts`,检查一下是否生效了:

    bash# echo 127.0.0.1 my-test-domain.com >> /etc/workaround-docker-2267/hosts
    bash# ping my-test-domain.com
    ...should ping 127.0.0.1...

**注意apt-get升级:** 如果Ubuntu升级,就有可能将`libnss_files.so.2`覆盖掉,那么修改就会失效.你必须重新运行`/usr/bin/workaround-docker-2267`.为了安全一点,你应该在运行`apt-get upgrade`之后,运行一下这个命令.

<a name="disabling_ssh"></a>
### 禁用SSH
Baseimage-docker默认是支持SSH的,所以可以[使用SSH](#login_ssh)来[管理你的容器](#container_administration).万一你不想支持SSH,你可以只要禁用它:

    RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

<a name="container_administration"></a>
## 容器管理

一个优秀的docker想法,就是docker是一个无状态的,容易启动的容器,就想一个黑盒子.然而,你可能遇到某种情况,需要登录到容器,或者运行命令在容器中.或者为了开发,需要查看或者debug的目的.这章就给你讲解怎么管理容器.


<a name="oneshot"></a>
### 在一个新容器中运行一个一闪而过的命令

_**备注:** 这章讲解怎么在一个-新-容器中运行命令.要在一个存在的容器中运行命令,请查看[在一个存在的容器中,运行一个命令](#run_inside_existing_container)._

正常情况下,当你创建了一个新容器,为了在容器中运行一个单独的命令,而且在运行之后会立即退出的,你会这样调用docker命令:

    docker run YOUR_IMAGE COMMAND ARGUMENTS...

然而下面的方法初始化系统的进行是不会启动.它是这样的,当调用`COMMAND`的时候,重要的后台进程,例如定时任务和系统日志都是不运行的.同样,子进程也是不会出现的,因为`COMMAND`的pid是1.

Baseimage-docker提供了一个灵活的方式运行只要一闪而过的命令,同时也解决了上述所说的问题.以一下的方式运行一条命令:

    docker run YOUR_IMAGE /sbin/my_init -- COMMAND ARGUMENTS ...

他们会按照下面的流程执行:

 * 运行所有的启动文件,例如 /etc/my_init.d/* and /etc/rc.local.
 * 运行所有的runit服务
 * 运行指定的命令
 * 运行指定的命令结束之后,结束所有runit服务.

例如:

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

你会发现默认的启动的流程太负责.或者你不希望执行启动文件.你可以自定义所有通过给`my_init`增加参数.调用`docker run YOUR_IMAGE /sbin/my_init --help`可以看到帮助信息.

例如上面运行`ls`命令,同时要求不运行启动脚本,减少信息打印,运行runit所有命令.

    $ docker run phusion/baseimage:<VERSION> /sbin/my_init --skip-startup-files --quiet -- ls
    bin  boot  dev  etc  home  image  lib  lib64  media  mnt  opt  proc  root  run  sbin  selinux  srv  sys  tmp  usr  var

<a name="run_inside_existing_container"></a>
### 在一个已经运行的容器中,运行一条命令

这里有两种办法去在一个已经运行的容器中运行命令.

 * 通过`nseneter`工具.这个工具用于Linux内核调用在内嵌容器中运行命令.可以查看[通过`nsenter`,登录容器或者在容器内执行命令](#login_nsenter).
 * 通过SSH.这种办法需要在容器中运行ssh服务,而且需要你创建自己的sshkey.可以查看[通过`ssh`,登录容器或者在容器内执行命令](#login_ssh).

两种方法都是他们各自的优点和确定,你可以学习他们各自的章节来了他们.

<a name="login_nsenter"></a>
### 通过`nsenter`,登录容器或者在容器内执行命令

你可以使用在docker主机上面的`nsenter`工具,来登录任何基于baseimage-docker的docker容器.你可以使用它在你的容器中运行命令.

这里有个和[通过`ssh`,登录容器或者在容器内执行命令](#login_ssh)的优缺点的比较:

 * 优点
   * 不需要在容器中运行ssh服务.
   * 不需要ssh key.
   * 运行在任何容器上,甚至不是基于baseimage-docker的容器.
 * 缺点
   * 通过`nsenter`运行的进程会和正常运行稍微有不同.例如,他们不同结束掉在容器中正常运行的进程.这适用于所有的子进程.
   * 如果`nsenter`进程被其他命令(如`kill`命令)给终止,然后由nsenter所执行的命令,是*不会*被结束的.你将不得不手动清理.(备注:终端控制命令像Ctrl-C *会* 清理所有的子进程,因为终端信号被发送到所有流程的终端会话)
   * 需要学习新工具.
   * 需要在docker主机上面提供root权限.
   * 需要在docker主机上面是可用的.在写这篇文字的时候(2014年7月),大多数linux发行版没有加载它.然而,baseimage-docker提供了预编译的二进制文件,允许你通过[docker-bash](#docker_bash)工具,来很容易的使用它.
   * 不可能没有登录到docker主机,就登录到docker容器中.(也就是说,你必须登录到docker主机,通过docker主机登录到容器.)

<a name="nsenter_usage"></a>
#### 用例

第一,确定`nsenter`已经安装了.在写这篇文字的时候(2014年7月),大多数linux发行版没有加载它.然而,baseimage-docker提供了预编译的二进制文件,允许你通过[docker-bash](#docker_bash)工具,让任何人都可以使用.

接着,启动一个容器.

    docker run YOUR_IMAGE

找出你刚才运行容器的`ID`.

    docker ps

一旦拥有容器的id,找到运行容器的主要进程额`PID`.

    docker inspect -f "{{ .State.Pid }}" <ID>

现在你有的容器的主进程的PID,就可以使用`nsenter`来登录容器,或者在容器里面执行命令:

    # 登录容器
    nsenter --target <MAIN PROCESS PID> --mount --uts --ipc --net --pid bash -l

    # 在容器中执行命令
    nsenter --target <MAIN PROCESS PID> --mount --uts --ipc --net --pid -- echo hello world

<a name="docker_bash"></a>
#### `docker-bash`工具

查找一个容器的主要进程的PID和输入这么长的nsenter命令很快会变得乏味无论.幸运的是,我们提供了一个`docker-bash` 工具,它可以自动完成只要的工具.这个工具是运行在*docker主机*上面,不是在docker容器中.

该工具还附带了一个预编译的二进制`nsenter`,这样你不需要自己安装`nsenter`了.`docker-bash`是很简单的使用的.

首先,在docker主机上安装这个工具:

    curl --fail -L -O https://github.com/phusion/baseimage-docker/archive/master.tar.gz && \
    tar xzf master.tar.gz && \
    sudo ./baseimage-docker-master/install-tools.sh

运行这个工具登录到容器中:

    docker-bash YOUR-CONTAINER-ID

你可以通过`docker ps`来查找你的容器ID.

默认,`docker-bash`会打开一个bash 回话.你可以告诉运行什么命令,之后就会自动退出:

    docker-bash YOUR-CONTAINER-ID echo hello world

<a name="login_ssh"></a>
### 通过`ssh`,登录容器或者在容器内执行命令

你可以使用ssh来登录任何基于baseimage-docker的容器.你可以使用它在容器中执行命令.

这里有个和[通过`nsenter`,登录容器或者在容器内执行命令](#login_nsenter)的优缺点的比较:

 * 优点
   * 不像`nsenter`一样,运行在docker主机上面.几乎每个人都会安装一个ssh客户端.
   * 不想使用`nsenter`,运行的进程和正在的进程会不一样.
   * 不需要docker主机提供root权限.
   * 运行你让用户登录到容器,而不需要登录到docker主机.然而,默认这是不启用的,因为baseimage-docker默认不是开放ssh服务的.
 *　缺点
   * 需要设置ssh key.然而,baseimage-docker会提供一中办法,会让key的生成会很容器.阅读更多信息.

第一件事情,就是你需要确定你在容器中已经安装设置了ssh key. 默认,没有任何安装key的,所有你无法登录.为了方便的原因,我们提供了一个[已经生成的key](https://github.com/phusion/baseimage-docker/blob/master/image/services/sshd/keys/insecure_key) [(PuTTY format)](https://github.com/phusion/baseimage-docker/blob/master/image/services/sshd/keys/insecure_key.ppk),为了让你使用方便.然后,请注意这个key仅仅是为方便.他没有任何安全行,因为它的key是在网络上提供的.**在生产环境,你必须使用你自己的key.**


<a name="using_the_insecure_key_for_one_container_only"></a>
#### 在容器中使用key

你可以临时的使用key仅仅作为容器使用.这就以为这key是安装在容器上的.如果你使用`docker stop`和`docker start`控制容器,那么key是在容器中,但是如果你使用`docker run`开启一个新容器,那么这个容器是不包含key的.

启动新容器包含key`--enable-insecure-key`:

    docker run YOUR_IMAGE /sbin/my_init --enable-insecure-key

找出你的刚才运行的容器的ID:

    docker ps

一旦你拥有容器的ID,就能找到容器使用的IP地址:

    docker inspect -f "{{ .NetworkSettings.IPAddress }}" <ID>

现在你有得了IP地址,你就看通过SSH来登录容器,或者在容器中执行命令了:

    # 下载key
    curl -o insecure_key -fSL https://github.com/phusion/baseimage-docker/raw/master/image/services/sshd/keys/insecure_key
    chmod 600 insecure_key

    # 登录容器
    ssh -i insecure_key root@<IP address>

    # 在容器中执行命令
    ssh -i insecure_key root@<IP address> echo hello world

<a name="enabling_the_insecure_key_permanently"></a>
#### 支持一个长久的key

在一个长久存在的镜像中支持一个key是很可能的.一般是不推荐这么做,但是对于临时开始或者做demo演示,对安全要求不高,还是很合适的.

编辑你的dockerfile,来安装永久的key:

    RUN /usr/sbin/enable_insecure_key

在容器中怎么使用,同[在容器中使用key](#using_the_insecure_key_for_one_container_only)的章节说的一样.

<a name="using_your_own_key"></a>
#### 使用你自己的key

编辑你的dockerfile,来安装ssh public key:

    ## 安装你自己的public key.
    ADD your_key.pub /tmp/your_key.pub
    RUN cat /tmp/your_key.pub >> /root/.ssh/authorized_keys && rm -f /tmp/your_key.pub

重新创建你的镜像.一旦你创建成功,启动基于这个镜像的容器.

    docker run your-image-name

找出你的刚才运行的容器的ID:

    docker ps

一旦你拥有容器的ID,就能找到容器使用的IP地址:

    docker inspect -f "{{ .NetworkSettings.IPAddress }}" <ID>

现在你有得了IP地址,你就看通过SSH来登录容器,或者在容器中执行命令了:

    # 登录容器
    ssh -i /path-to/your_key root@<IP address>

    # 在容器中执行命令
    ssh -i /path-to/your_key root@<IP address> echo hello world

<a name="docker_ssh"></a>
#### `docker-ssh`工具

找到容器的IP,运行ssh命令,很快会变得乏味无聊.幸运的是,我们提供了一个`docker-ssh`,可以自动完成这些事情.这个工具是运行在*Docker 主机*上的,不是安装在docker容器中的.

首先,在docker主机上面安装这个工具.

    curl --fail -L -O https://github.com/phusion/baseimage-docker/archive/master.tar.gz && \
    tar xzf master.tar.gz && \
    sudo ./baseimage-docker-master/install-tools.sh

使用这个工具通过ssh登录容器:

    docker-ssh YOUR-CONTAINER-ID

你可以使用`docker ps`找到`YOUR-CONTAINER-ID`.

默认,`docker-bash`会打开一个bash 回话.你可以告诉运行什么命令,之后就会自动退出:

    docker-ssh YOUR-CONTAINER-ID echo hello world

<a name="building"></a>
## 创建你自己的镜像

如果某些原因,你需要创建你自己的镜像,来替代从docker仓库下载镜像,可以按照的说明.

克隆仓库:

    git clone https://github.com/phusion/baseimage-docker.git
    cd baseimage-docker

创建一个包含docker在的虚拟机.你可以使用我们提供的Vagrantfile.

    vagrant up
    vagrant ssh
    cd /vagrant

编译镜像:

    make build

如果你想把创建的镜像名字,叫其他名字,通过`NAME`变量可以设置:

    make build NAME=joe/baseimage

<a name="conclusion"></a>
## 总结

 * Using baseimage-docker? [Tweet about us](https://twitter.com/share) or [follow us on Twitter](https://twitter.com/phusion_nl).
 * Having problems? Want to participate in development? Please post a message at [the discussion forum](https://groups.google.com/d/forum/passenger-docker).
 * Looking for a more complete base image, one that is ideal for Ruby, Python, Node.js and Meteor web apps? Take a look at [passenger-docker](https://github.com/phusion/passenger-docker).

[<img src="http://www.phusion.nl/assets/logo.png">](http://www.phusion.nl/)

Please enjoy baseimage-docker, a product by [Phusion](http://www.phusion.nl/). :-)
