<a name="a-minimal-ubuntu-base-image-modified-for-docker-friendliness"></a>
# Docker友好的，最小的Ubuntu基礎鏡像

Baseimage-docker是一個特殊的[Docker](http://www.docker.io)鏡像，在Docker容器內做了配置，並且可以正確使用。它確實是一個Ubuntu系統, 除此之外進行了如下修訂：

 * 爲更加友好的支持Docker，做了修訂。
 * 在Docker環境下，作爲管理工具特別有用。
 * 在[不違反Docker哲學](#docker_single_process)的前提下，能夠很容易的運行多行程的機制。

可以把它作爲自己的基礎Docker鏡像。

Baseimage-docker項目可以直接從Docker的[registry](https://index.docker.io/u/phusion/baseimage/)獲取！
        
<a name="what-are-the-problems-with-the-stock-ubuntu-base-image"></a>
### 原生的Ubuntu基礎鏡像有什麼問題呢？          
            
原生Ubuntu不是爲了在Docker內運行而設計的。它的初始化系統Upstart，假定運行的環境要麼是真實的硬體，要麼是虛擬的硬體，而不是在Docker容器內。但是在一個Docker的容器內，並不需要一個完整的系統，你需要的只是一個很小的系統。但是如果你不是非常熟悉Unix的系統模型，想要在Docker容器內裁減出最小的系統，會碰到很多難以正確解決的陌生的技術坑。這些坑會引起很多莫名其妙的問題。

Baseimage-docker讓這一切完美。在"內容"部分描述了所有這些修改。

<a name="why-use-baseimage-docker"></a>
### 爲什麼使用baseimage-docker？

你自己可以從Dockerfile配置一個原生`ubuntu`鏡像，爲什麼還要多此一舉的使用baseimage-docker呢?
        
 * 配置一個Docker友好的基礎系統並不是一個簡單的任務。如前所述，過程中會碰到很多坑。當你搞定這些坑之後，只不過是又重新發明了一個baseimage-docker而已。使用baseimage-docker可以免去你這方面需要做的努力。          
 * 減少需要正確編寫Dockerfile文件的時間。你不用再擔心基礎系統，可以專注於你自己的技術棧和你的項目。            
 * 減少需要運行`docker build`的時間，讓你更快的迭代Dockerfile。         
 * 減少了重新部署的時的下載時間。Docker只需要在第一次部署的時候下載一次基礎鏡像。在隨後的部署中,只需要改變你下載之後對基礎鏡像進行修改的部分。

-----------------------------------------

**相關資源**

  [網站](http://phusion.github.io/baseimage-docker/) |
  [Github](https://github.com/phusion/baseimage-docker) |
  [Docker registry](https://index.docker.io/u/phusion/baseimage/) |
  [論壇](https://groups.google.com/d/forum/passenger-docker) |
  [Twitter](https://twitter.com/phusion_nl) |
  [Blog](http://blog.phusion.nl/)

**目錄**

 * [鏡像裏面有什麼?](#whats_inside)
   * [概述](#whats_inside_overview)
   * [等等,我認爲Docker在一個容器中只能允許運行一個行程?](#docker_single_process)           
   * [Baseimage-docker更側重於“胖容器”還是“把容器當作虛擬機”？](#fat_containers)            
 * [查看baseimage-docker](#inspecting)
 * [使用baseimage-docker作爲基礎鏡像](#using)
   * [開始](#getting_started)
   * [增加額外的後臺行程](#adding_additional_daemons)
   * [容器啓動時運行腳本](#running_startup_scripts)
   * [環境變數](#environment_variables)
     * [集中定義自己的環境變數](#envvar_central_definition)
     * [保存環境變數](#envvar_dumps)
     * [修改環境變數](#modifying_envvars)
     * [安全性](#envvar_security)
 * [容器管理](#container_administration)
   * [在一個新容器中運行單條命令](#oneshot)
   * [在正在運行的的容器中運行一條命令](#run_inside_existing_container)
   * [通過`docer exec`登錄容器](#login_docker_exec)
     * [用法](#nsenter_usage)
   * [使用SSH登錄容器](#login_ssh)
     * [啓用SSH](#enabling_ssh)
     * [關於SSH的key](#ssh_keys)
     * [只對一個容器使用不安全key](#using_insecure_key_for_one_container_only)
     * [永久開啓不安全key](#enabling_the_insecure_key_permanently)
     * [使用你自己的key](#using_your_own_key)
     * [`docker-ssh`工具](#docker_ssh)
 * [構建自己的鏡像](#building)
 * [總結](#conclusion)

-----------------------------------------

<a name="whats_inside"></a>
## 鏡像裏面有什麼？

<a name="whats_inside_overview"></a>
### 概述

*想看一個裏面包含Ruby，Python，Node.js以及Meteor的完整基礎鏡像？可以看一下[passenger-docker](https://github.com/phusion/passenger-docker)。*            

| 模塊        | 爲什麼包含這些？以及備註 |
| ---------------- | ------------------- |
| Ubuntu 14.04 LTS | 基礎系統。 |
| 一個**正確**的初始化行程  | *主要文章：[Docker和PID 1 殭屍行程回收問題](http://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)*<br/><br/>根據Unix行程模型，[初始化行程](https://en.wikipedia.org/wiki/Init) -- PID 1 -- 繼承了所有[孤立的子行程](https://en.wikipedia.org/wiki/Orphan_process)，並且必須[進行回收](https://en.wikipedia.org/wiki/Wait_(system_call))。大多數Docker容器沒有一個初始化行程可以正確的完成此操作，隨着時間的推移會導致他們的容器出現了大量的[殭屍行程](https://en.wikipedia.org/wiki/Zombie_process)。<br/><br/>而且，`docker stop`發送SIGTERM信號給初始化行程，照理說此信號應該可以停止所有服務。不幸的是由於它們對硬體進行了關閉操作，導致Docker內的大多數初始化系統沒有正確執行。這會導致行程強行被SIGKILL信號關閉，從而喪失了一個正確取消初始化設置的機會。這會導致文件損壞。<br/><br/>Baseimage-docker配有一個名爲`/sbin/my_init`的初始化行程來同時正確的完成這些任務。 |
| 修復了APT與Docker不兼容的問題 | 詳情參見：https://github.com/dotcloud/docker/issues/1024 。 |
| syslog-ng | 對於很多服務－包括kernel自身，都需要一個syslog後臺行程，以便可以正確的將log輸出到/var/log/syslog中。如果沒有運行syslog後臺行程，很多重要的信息就會默默的丟失了。<br/><br/>只對本地進行監聽。所有syslog信息會被轉發給“docker logs”。 |
| logrotate | 定期轉存和壓縮日誌。 |
| SSH服務 | 允許你很容易的登錄到容器中進行[查詢或管理](#login_ssh)操作。<br/><br/>_SSH**默認是禁用**的，這也是baseimage-docker爲此目的提供的唯一方法。其它方法需要通過[docker exec](#login_docker_exec)。由於`docker exec`同時帶來了幾個需要注意的問題，SSH同時也提供了一個可替換的方法。_<br/><br/>密碼和challenge-response認證方式默認是禁用的。只有key認證通過之後才能夠開啓。 |
| cron | 爲了保證cron任務能夠工作，必須運行cron後臺行程。 |
| [runit](http://smarden.org/runit/) | 替換Ubuntu的Upstart。用於服務監控和管理。比SysV init更容易使用，同時當這些服務崩潰之後，支持後臺行程自動重啓。比Upstart更易使用，更加的輕量級。 |
| `setuser` | 使用其它賬戶運行命令的工具。比`su`更容易使用，比使用`sudo`有那麼一點優勢，跟`chpst`不同，這個工具需要正確的設置`$HOME`。像`/sbin/setuser`這樣。 |
Baseimage-docker非常的輕量級：僅僅佔用6MB內存。

<a name="docker_single_process"></a>
### 等等,我認爲Docker在一個容器中就運行一個行程嗎?
絕對不是這樣的. 在一個docker容器中,運行多個行程也是很好的. 事實上,沒有什麼技術原因限制你只運行一個行程,運行很多的行程,只會把容器中系統的基本功能搞的更亂,比如syslog.

Baseimage-docker *鼓勵* 通過runit來運行多行程.

<a name="inspecting"></a>
## 檢測一下baseimage-docker

要檢測鏡像,執行下面的命令:

    docker run --rm -t -i phusion/baseimage:<VERSION> /sbin/my_init -- bash -l

`<VERSION>` 是[baseimage-docker的版本號](https://github.com/phusion/baseimage-docker/blob/master/Changelog.md).

你不用手動去下載任何文件.上面的命令會自動從docker倉庫下載baseimage-docker鏡像.

<a name="using"></a>
## 使用baseimage-docker作爲基礎鏡像

<a name="getting_started"></a>
### 入門指南

The image is called `phusion/baseimage`, and is available on the Docker registry.
鏡像名字叫`phusion/baseimage`,在Docker倉庫上也是可用的.

下面的這個是一個Dockerfile的模板.

	# 使用phusion/baseimage作爲基礎鏡像,去構建你自己的鏡像,需要下載一個明確的版本,千萬不要使用`latest`.
	# 查看https://github.com/phusion/baseimage-docker/blob/master/Changelog.md,可用看到版本的列表.
	FROM phusion/baseimage:<VERSION>
	
	# 設置正確的環境變數.
	ENV HOME /root
	
	# 生成SSH keys,baseimage-docker不包含任何的key,所以需要你自己生成.你也可以註釋掉這句命令,系統在啓動過程中,會生成一個.
	RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
	
	# 初始化baseimage-docker系統
	CMD ["/sbin/my_init"]
	
	# 這裏可以放置你自己需要構建的命令
	
	# 當完成後,清除APT.
	RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


<a name="adding_additional_daemons"></a>
### 增加後臺行程

你可以通過runit工具向你的鏡像中添加後臺行程(例如:你自己的某些應用).你需要編寫一個運行你需要的後臺行程的腳步就可以了,runit工具會保證它的正常運行,如果行程死掉,runit也會重啓它的.

腳本的名稱必須是`run`,必須是可以運行的,它需要放到`/etc/service/<NAME>`.

這裏有一個例子,向你展示如果運行memcached服務的.

	### memcached.sh(確定文件的權限是chmod +x):
	#!/bin/sh
	# `/sbin/setuser memcache` 指定一個`memcache`用戶來運行命令.如果你忽略了這部分,就會使用root用戶執行.
	exec /sbin/setuser memcache /usr/bin/memcached >>/var/log/memcached.log 2>&1
	
	### 在Dockerfile中:
    RUN mkdir /etc/service/memcached
    ADD memcached.sh /etc/service/memcached/run

注意腳本必須運行在後臺的,**不能讓他們行程進行daemonize/fork**.通常,後臺行程會提供一個標誌位或者配置文件.

<a name="running_startup_scripts"></a>
### 在容器啓動的時候,運行腳本.

baseimage-docker的初始化腳本 `/sbin/my_init`,在啓動的時候行程運行,按照下面的順序:

 * 如果`/etc/my_init.d`存在,則按照字母順序執行腳本.
 * 如果`/etc/rc.local`存在,則執行裏面的腳本.

所有的腳本都是正確退出的,例如:退出的code是0.如果有任何腳本以非0的code退出,啓動就會失敗.

下面的例子向你展示了怎麼添加一個啓動腳本.這個腳本很簡單的記錄的一個系統啓動時間,將啓動時間記錄到/tmp/boottime.txt.

    ### 在 logtime.sh (文件權限chmod +x):
    #!/bin/sh
    date > /tmp/boottime.txt

    ### 在 Dockerfile中:
    RUN mkdir -p /etc/my_init.d
    ADD logtime.sh /etc/my_init.d/logtime.sh


<a name="environment_variables"></a>
### 環境變數

如果你使用`/sbin/my_init`作爲主容器命令,那麼通過`docker run --env`或者在Dockerfile文件中設置的`ENV`環境變數,都會被`my_init`讀取.

 * 在Unix系統中,環境變數都會被子行程給繼承.這就意味着,子行程不可能修改環境變數或者修改其他行程的環境變數.
 * 由於上面提到的一點,這裏沒有一個可以爲所有應用和服務集中定義環境的地方.Debian提供了一個`/etc/environment` 文件,解決一些問題.
 * 某些服務更改環境變數是爲了給子行程使用.Nginx有這樣的一個例子:它移除了所有的環境變數,除非你通過`env`進行了配置,明確了某些是保留的.如果你部署了任何應用在Nginx鏡像(例如:使用[passenger-docker](https://github.com/phusion/passenger-docker)鏡像或者使用Phusion Passenger作爲你的鏡像.),那麼你通過Docker,你不會看到任何環境變數.
 

`my_init`提供了一個辦法來解決這些問題.

<a name="envvar_central_definition"></a>
#### 集中定義你的環境變數

在啓動的時候,在執行[startup scripts](#running_startup_scripts),`my_init`會從`/etc/container_environment`導入環境變數.這個文件夾下面,包含的文件,文件被命名爲環境變數的名字.文件內容就是環境變數的值.這個文件夾是因此是一個集中定義你的環境變數的好地方,它會繼承到所有啓動項目和Runit管理的服務中.

給個例子,在你的dockerfile如何定義一個環境變數:

    RUN echo Apachai Hopachai > /etc/container_environment/MY_NAME

你可以按照下面這樣驗證:

    $ docker run -t -i <YOUR_NAME_IMAGE> /sbin/my_init -- bash -l
    ...
    *** Running bash -l...
    # echo $MY_NAME
    Apachai Hopachai

**換行處理**

如果你觀察仔細一點,你會注意到'echo'命令,實際上在它是在新行打印出來的.爲什麼$MY_NAME沒有包含在一行呢? 因爲`my_init`在尾部有個換行字符.如果你打算讓你的值包含一個新行,你需要增*另外*一個新字符,像這樣:

    RUN echo -e "Apachai Hopachai\n" > /etc/container_environment/MY_NAME

<a name="envvar_dumps"></a>
#### 環境變數存儲

上面提到集中定義環境變數,它不會從子服務行程改變父服務行程或者重置環境變數.而且,`my_init`也會很容易的讓你查詢到原始的環境變數是什麼.

在啓動的時候,`/etc/container_environment`, `my_init`中的變數會存儲起來,並且導入到環境變數中,例如一下的格式:

 * `/etc/container_environment`
 * `/etc/container_environment.sh`- 一個bash存儲的環境變數格式.你可以從這個命令中得到base格式的文件.
 * `/etc/container_environment.json` - 一個json格式存儲的環境變數格式.

多種格式可以讓你不管採用什麼語言/apps都可以很容易使用環境變數.

這裏有個例子,展示怎麼使用:

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
#### 修改環境變數

通過修改`/etc/container_environment`這個文件,很有可能修改了`my_init`中的環境變數.之後,每次`my_init`啓動[啓動腳本](#running_startup_scripts),就會重置掉我們自己`/etc/container_environment`中的環境變數,也就會導致`container_environment.sh`和`container_environment.json`重新存儲.

但是記住這些:

 * 修改`container_environment.sh` 和 `container_environment.json`是沒有效果的.
 * Runit 的服務是不能像這樣修改環境變數的.`my_init`運行的時候,只對`/etc/container_environment`中的修改是生效的.

<a name="envvar_security"></a>
#### 安全

因爲環境變數可能包含敏感信息, `/etc/container_environment`和它的bash文件和JSON文件,默認都是root,都是可以被`docker_env`羣組可以訪問的(所以任何用戶只要添加到羣組中,都可以自動的獲取這些信息).

如果你確定你的環境變數中沒有什麼敏感信息,那麼你可以放鬆管理權限,將文件夾和文件分配下面的權限:

    RUN chmod 755 /etc/container_environment
    RUN chmod 644 /etc/container_environment.sh /etc/container_environment.json

<a name="workaroud_modifying_etc_hosts"></a>
### 解決Docker沒有辦法解決的/etc/hosts的問題

當前是沒有辦法在docker容器中修改`/etc/hosts`,這個是因爲[Docker bug 2267](https://github.com/dotcloud/docker/issues/2267).Baseimage-docker包含了解決這個問題的辦法,你必須明白是怎麼修改的.

修改的辦法包含在系統庫中的` libnss_files.so.2`文件,這個文件使用`/etc/workaround-docker-2267/hosts`來代替系統使用`/etc/hosts`.如果需要修改`/etc/hosts`,你只要修改`/etc/workaround-docker-2267/hosts`就可以了.

增加這個修改到你的Dockerfile.下面的命令修改了文件`libnss_files.so.2`.

    RUN /usr/bin/workaround-docker-2267

(其實你不用在Dockerfile文件中運行這個命令,你可以在容器中運行一個shell就可以了.)

驗證一下它是否生效了,[在你的容器中打開一個shell](#inspecting),修改`/etc/workaround-docker-2267/hosts`,檢查一下是否生效了:

    bash# echo 127.0.0.1 my-test-domain.com >> /etc/workaround-docker-2267/hosts
    bash# ping my-test-domain.com
    ...should ping 127.0.0.1...

**注意apt-get升級:** 如果Ubuntu升級,就有可能將`libnss_files.so.2`覆蓋掉,那麼修改就會失效.你必須重新運行`/usr/bin/workaround-docker-2267`.爲了安全一點,你應該在運行`apt-get upgrade`之後,運行一下這個命令.

<a name="disabling_ssh"></a>
### 禁用SSH
Baseimage-docker默認是支持SSH的,所以可以[使用SSH](#login_ssh)來[管理你的容器](#container_administration).萬一你不想支持SSH,你可以只要禁用它:

    RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

<a name="container_administration"></a>
## 容器管理

一個優秀的docker想法,就是docker是一個無狀態的,容易啓動的容器,就想一個黑盒子.然而,你可能遇到某種情況,需要登錄到容器,或者運行命令在容器中.或者爲了開發,需要查看或者debug的目的.這章就給你講解怎麼管理容器.


<a name="oneshot"></a>
### 在一個新容器中運行一個一閃而過的命令

_**備註:** 這章講解怎麼在一個-新-容器中運行命令.要在一個存在的容器中運行命令,請查看[在一個存在的容器中,運行一個命令](#run_inside_existing_container)._

正常情況下,當你創建了一個新容器,爲了在容器中運行一個單獨的命令,而且在運行之後會立即退出的,你會這樣調用docker命令:

    docker run YOUR_IMAGE COMMAND ARGUMENTS...

然而下面的方法初始化系統的進行是不會啓動.它是這樣的,當調用`COMMAND`的時候,重要的後臺行程,例如定時任務和系統日誌都是不運行的.同樣,子行程也是不會出現的,因爲`COMMAND`的pid是1.

Baseimage-docker提供了一個靈活的方式運行只要一閃而過的命令,同時也解決了上述所說的問題.以一下的方式運行一條命令:

    docker run YOUR_IMAGE /sbin/my_init -- COMMAND ARGUMENTS ...

他們會按照下面的流程執行:

 * 運行所有的啓動文件,例如 /etc/my_init.d/* and /etc/rc.local.
 * 運行所有的runit服務
 * 運行指定的命令
 * 運行指定的命令結束之後,結束所有runit服務.

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

你會發現默認的啓動的流程太負責.或者你不希望執行啓動文件.你可以自定義所有通過給`my_init`增加參數.調用`docker run YOUR_IMAGE /sbin/my_init --help`可以看到幫助信息.

例如上面運行`ls`命令,同時要求不運行啓動腳本,減少信息打印,運行runit所有命令.

    $ docker run phusion/baseimage:<VERSION> /sbin/my_init --skip-startup-files --quiet -- ls
    bin  boot  dev  etc  home  image  lib  lib64  media  mnt  opt  proc  root  run  sbin  selinux  srv  sys  tmp  usr  var

<a name="run_inside_existing_container"></a>
### 在一個已經運行的容器中,運行一條命令

這裏有兩種辦法去在一個已經運行的容器中運行命令.

 * 通過`nseneter`工具.這個工具用於Linux內核調用在內嵌容器中運行命令.可以查看[通過`nsenter`,登錄容器或者在容器內執行命令](#login_nsenter).
 * 通過SSH.這種辦法需要在容器中運行ssh服務,而且需要你創建自己的sshkey.可以查看[通過`ssh`,登錄容器或者在容器內執行命令](#login_ssh).

兩種方法都是他們各自的優點和確定,你可以學習他們各自的章節來了他們.

<a name="login_nsenter"></a>
### 通過`nsenter`,登錄容器或者在容器內執行命令

你可以使用在docker主機上面的`nsenter`工具,來登錄任何基於baseimage-docker的docker容器.你可以使用它在你的容器中運行命令.

這裏有個和[通過`ssh`,登錄容器或者在容器內執行命令](#login_ssh)的優缺點的比較:

 * 優點
   * 不需要在容器中運行ssh服務.
   * 不需要ssh key.
   * 運行在任何容器上,甚至不是基於baseimage-docker的容器.
 * 缺點
   * 通過`nsenter`運行的行程會和正常運行稍微有不同.例如,他們不同結束掉在容器中正常運行的行程.這適用於所有的子行程.
   * 如果`nsenter`行程被其他命令(如`kill`命令)給終止,然後由nsenter所執行的命令,是*不會*被結束的.你將不得不手動清理.(備註:終端控制命令像Ctrl-C *會* 清理所有的子行程,因爲終端信號被髮送到所有流程的終端會話)
   * 需要學習新工具.
   * 需要在docker主機上面提供root權限.
   * 需要在docker主機上面是可用的.在寫這篇文字的時候(2014年7月),大多數linux發行版沒有加載它.然而,baseimage-docker提供了預編譯的二進制文件,允許你通過[docker-bash](#docker_bash)工具,來很容易的使用它.
   * 不可能沒有登錄到docker主機,就登錄到docker容器中.(也就是說,你必須登錄到docker主機,通過docker主機登錄到容器.)

<a name="nsenter_usage"></a>
#### 用例

第一,確定`nsenter`已經安裝了.在寫這篇文字的時候(2014年7月),大多數linux發行版沒有加載它.然而,baseimage-docker提供了預編譯的二進制文件,允許你通過[docker-bash](#docker_bash)工具,讓任何人都可以使用.

接着,啓動一個容器.

    docker run YOUR_IMAGE

找出你剛纔運行容器的`ID`.

    docker ps

一旦擁有容器的id,找到運行容器的主要行程額`PID`.

    docker inspect -f "{{ .State.Pid }}" <ID>

現在你有的容器的主行程的PID,就可以使用`nsenter`來登錄容器,或者在容器裏面執行命令:

    # 登錄容器
    nsenter --target <MAIN PROCESS PID> --mount --uts --ipc --net --pid bash -l

    # 在容器中執行命令
    nsenter --target <MAIN PROCESS PID> --mount --uts --ipc --net --pid -- echo hello world

<a name="docker_bash"></a>
#### `docker-bash`工具

查找一個容器的主要行程的PID和輸入這麼長的nsenter命令很快會變得乏味無論.幸運的是,我們提供了一個`docker-bash` 工具,它可以自動完成只要的工具.這個工具是運行在*docker主機*上面,不是在docker容器中.

該工具還附帶了一個預編譯的二進制`nsenter`,這樣你不需要自己安裝`nsenter`了.`docker-bash`是很簡單的使用的.

首先,在docker主機上安裝這個工具:

    curl --fail -L -O https://github.com/phusion/baseimage-docker/archive/master.tar.gz && \
    tar xzf master.tar.gz && \
    sudo ./baseimage-docker-master/install-tools.sh

運行這個工具登錄到容器中:

    docker-bash YOUR-CONTAINER-ID

你可以通過`docker ps`來查找你的容器ID.

默認,`docker-bash`會打開一個bash 回話.你可以告訴運行什麼命令,之後就會自動退出:

    docker-bash YOUR-CONTAINER-ID echo hello world

<a name="login_ssh"></a>
### 通過`ssh`,登錄容器或者在容器內執行命令

你可以使用ssh來登錄任何基於baseimage-docker的容器.你可以使用它在容器中執行命令.

這裏有個和[通過`nsenter`,登錄容器或者在容器內執行命令](#login_nsenter)的優缺點的比較:

 * 優點
   * 不像`nsenter`一樣,運行在docker主機上面.幾乎每個人都會安裝一個ssh客戶端.
   * 不想使用`nsenter`,運行的行程和正在的行程會不一樣.
   * 不需要docker主機提供root權限.
   * 運行你讓用戶登錄到容器,而不需要登錄到docker主機.然而,默認這是不啓用的,因爲baseimage-docker默認不是開放ssh服務的.
 *　缺點
   * 需要設置ssh key.然而,baseimage-docker會提供一中辦法,會讓key的生成會很容器.閱讀更多信息.

第一件事情,就是你需要確定你在容器中已經安裝設置了ssh key. 默認,沒有任何安裝key的,所有你無法登錄.爲了方便的原因,我們提供了一個[已經生成的key](https://github.com/phusion/baseimage-docker/blob/master/image/services/sshd/keys/insecure_key) [(PuTTY format)](https://github.com/phusion/baseimage-docker/blob/master/image/services/sshd/keys/insecure_key.ppk),爲了讓你使用方便.然後,請注意這個key僅僅是爲方便.他沒有任何安全行,因爲它的key是在網絡上提供的.**在生產環境,你必須使用你自己的key.**


<a name="using_the_insecure_key_for_one_container_only"></a>
#### 在容器中使用key

你可以臨時的使用key僅僅作爲容器使用.這就以爲這key是安裝在容器上的.如果你使用`docker stop`和`docker start`控制容器,那麼key是在容器中,但是如果你使用`docker run`開啓一個新容器,那麼這個容器是不包含key的.

啓動新容器包含key`--enable-insecure-key`:

    docker run YOUR_IMAGE /sbin/my_init --enable-insecure-key

找出你的剛纔運行的容器的ID:

    docker ps

一旦你擁有容器的ID,就能找到容器使用的IP地址:

    docker inspect -f "{{ .NetworkSettings.IPAddress }}" <ID>

現在你有得了IP地址,你就看通過SSH來登錄容器,或者在容器中執行命令了:

    # 下載key
    curl -o insecure_key -fSL https://github.com/phusion/baseimage-docker/raw/master/image/services/sshd/keys/insecure_key
    chmod 600 insecure_key

    # 登錄容器
    ssh -i insecure_key root@<IP address>

    # 在容器中執行命令
    ssh -i insecure_key root@<IP address> echo hello world

<a name="enabling_the_insecure_key_permanently"></a>
#### 支持一個長久的key

在一個長久存在的鏡像中支持一個key是很可能的.一般是不推薦這麼做,但是對於臨時開始或者做demo演示,對安全要求不高,還是很合適的.

編輯你的dockerfile,來安裝永久的key:

    RUN /usr/sbin/enable_insecure_key

在容器中怎麼使用,同[在容器中使用key](#using_the_insecure_key_for_one_container_only)的章節說的一樣.

<a name="using_your_own_key"></a>
#### 使用你自己的key

編輯你的dockerfile,來安裝ssh public key:

    ## 安裝你自己的public key.
    ADD your_key.pub /tmp/your_key.pub
    RUN cat /tmp/your_key.pub >> /root/.ssh/authorized_keys && rm -f /tmp/your_key.pub

重新創建你的鏡像.一旦你創建成功,啓動基於這個鏡像的容器.

    docker run your-image-name

找出你的剛纔運行的容器的ID:

    docker ps

一旦你擁有容器的ID,就能找到容器使用的IP地址:

    docker inspect -f "{{ .NetworkSettings.IPAddress }}" <ID>

現在你有得了IP地址,你就看通過SSH來登錄容器,或者在容器中執行命令了:

    # 登錄容器
    ssh -i /path-to/your_key root@<IP address>

    # 在容器中執行命令
    ssh -i /path-to/your_key root@<IP address> echo hello world

<a name="docker_ssh"></a>
#### `docker-ssh`工具

找到容器的IP,運行ssh命令,很快會變得乏味無聊.幸運的是,我們提供了一個`docker-ssh`,可以自動完成這些事情.這個工具是運行在*Docker 主機*上的,不是安裝在docker容器中的.

首先,在docker主機上面安裝這個工具.

    curl --fail -L -O https://github.com/phusion/baseimage-docker/archive/master.tar.gz && \
    tar xzf master.tar.gz && \
    sudo ./baseimage-docker-master/install-tools.sh

使用這個工具通過ssh登錄容器:

    docker-ssh YOUR-CONTAINER-ID

你可以使用`docker ps`找到`YOUR-CONTAINER-ID`.

默認,`docker-bash`會打開一個bash 回話.你可以告訴運行什麼命令,之後就會自動退出:

    docker-ssh YOUR-CONTAINER-ID echo hello world

<a name="building"></a>
## 創建你自己的鏡像

如果某些原因,你需要創建你自己的鏡像,來替代從docker倉庫下載鏡像,可以按照的說明.

克隆倉庫:

    git clone https://github.com/phusion/baseimage-docker.git
    cd baseimage-docker

創建一個包含docker在的虛擬機.你可以使用我們提供的Vagrantfile.

    vagrant up
    vagrant ssh
    cd /vagrant

編譯鏡像:

    make build

如果你想把創建的鏡像名字,叫其他名字,通過`NAME`變數可以設置:

    make build NAME=joe/baseimage

<a name="conclusion"></a>
## 總結

 * Using baseimage-docker? [Tweet about us](https://twitter.com/share) or [follow us on Twitter](https://twitter.com/phusion_nl).
 * Having problems? Want to participate in development? Please post a message at [the discussion forum](https://groups.google.com/d/forum/passenger-docker).
 * Looking for a more complete base image, one that is ideal for Ruby, Python, Node.js and Meteor web apps? Take a look at [passenger-docker](https://github.com/phusion/passenger-docker).

[<img src="http://www.phusion.nl/assets/logo.png">](http://www.phusion.nl/)

Please enjoy baseimage-docker, a product by [Phusion](http://www.phusion.nl/). :-)
