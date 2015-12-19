## 0.9.18 (release date: 2015-12-08)

 * The latest OpenSSL updates have been pulled in. This fixes [CVE-2015-3193](https://www.openssl.org/news/secadv/20151203.txt) and a few others. Upgrading is strongly recommended.
 * Fixes disabling all services. Thanks to Enderson Maia.


## 0.9.17 (release date: 2015-07-15)

 * The latest OpenSSL updates have been pulled in. This fixes [CVE-2015-1793](http://openssl.org/news/secadv_20150709.txt). Upgrading is strongly recommended.
 * Removed nano and replaced vim with vim-tiny. This reduces Baseimage-docker's virtual size by 42 MB.
 * Fixed an issue in `my_init` which could cause it to hang during shutdown. Thanks to Joe "SAPikachu" Hu for contributing the fix. Closes GH-151.
 * When `my_init` generates `/etc/container_environment.sh`, it now ensures that environment variable names do not include any characters unsupported by Bash. Unsupported characters are now replaced with underscores. This fixes compatibility issues with Docker Compose. Closes GH-230.
 * `my_init` no longer reads from and writes to `/etc/container_environment` if that directory does not exist. Previously it would abort with an error. This change makes it easier to reuse `my_init` in other (non-Baseimage-docker-based) projects without having to modify it.
 * Baseimage-docker no longer sets the HOME environment variable by default. We used to set HOME by default to work around [Docker issue 2968](https://github.com/docker/docker/issues/2968) where HOME defaults to /, but this issue is now fixed. Furthermore, the fact that we set HOME interfered with the USER stanza: USER would no longer set HOME. So we got rid of our HOME variable. Closes GH-231.
 * Some unnecessary Ubuntu cron jobs have been removed. Closes GH-205.
 * Syslog-ng no longer forwards messages to /dev/tty10. Closes GH-222.
 * It is now possible to build your own Baseimage-docker variant that has cron, syslog or sshd disabled. Thanks to Enderson Tadeu S. Maia. Closes GH-182.

## 0.9.16 (release date: 2015-01-20)

 * `docker exec` is now the default and recommended mechanism for running commands in the container. SSH is now disabled by default, but is still supported for those cases where "docker exec" is not appropriate. Closes GH-168.
 * All syslog output is now forwarded to `docker logs`. Closes GH-123.
 * The workaround for Docker bug 2267 (the inability to modify /etc/hosts) has been removed, because it has been fixed upstream. Closes GH-155.
 * Logrotate now reloads syslog-ng properly. Closes GH-167.
 * Fixed some locale issues. Closes GH-178. Thanks to David J. M. Karlsen.
 * Fixed problems with cron. Closes GH-115.
 * Contribution by Bryan Bishop.

## 0.9.15 (release date: 2014-10-03)

 * Fixed the setuid bit on /usr/bin/sudo. This problem was caused by Docker bug #6828.

## 0.9.14 (release date: 2014-10-01)

 * Installed all the latest Ubuntu security updates. This patches Shellshock, among other things.
 * Some documentation updates by andreamtp.

## 0.9.13 (release date: 2014-08-22)

 * Fixed `my_init` not properly exiting with a non-zero exit status when Ctrl-C is pressed.
 * The GID of the `docker_env` group has been changed from 1000 to 8377, in order to avoid GID conflicts with any groups that you might want to introduce inside the container.
 * The syslog-ng socket is now deleted before starting the syslog-ng daemon, to avoid the daemon from failing to start due to garbage on the filesystem. Thanks to Kingdon Barrett. Closes GH-129.
 * Typo fixes by Arkadi Shishlov.

## 0.9.12 (release date: 2014-07-24)

 * We now officially support `nsenter` as an alternative way to login to the container. With official support, we mean that we've provided extensive documentation on how to use `nsenter`, as well as related convenience tools. However, because `nsenter` has various issues, and for backward compatibility reasons, we still support SSH. Please refer to the README for details about `nsenter`, and what the pros and cons are compared to SSH.
   * The `docker-bash` tool has been modified to use `nsenter` instead of SSH.
   * What was previously the `docker-bash` tool, has now been renamed to `docker-ssh`. It now also works on a regular sh shell too, instead of bash specifically.
 * Added a workaround for Docker's inability to modify /etc/hosts in the container ([Docker bug 2267](https://github.com/dotcloud/docker/issues/2267)). Please refer to the README for details.
 * Fixed an issue with SSH X11 forwarding. Thanks to Anatoly Bubenkov. Closes GH-105.
 * The init system now prints its own log messages to stderr. Thanks to mephi42. Closes GH-106.

## 0.9.11 (release date: 2014-06-24)

 * Introduced the `docker-bash` tool. This is a shortcut tool for logging into a container using SSH. Usage: `docker-bash <CONTAINER ID>`. See the README for details.
 * Fixed various process waiting issues in `my_init`. Closes GH-27, GH-82 and GH-83. Thanks to André Luiz dos Santos and Paul Annesley.
 * The `ca-certificates` package is now installed by default. This is because we include `apt-transport-https`, but Ubuntu 14.04 no longer installs `ca-certificates` by default anymore. Closes GH-73.
 * Output print by Runit services are now redirected to the Docker logs instead of to proctitle. Thanks to Paul Annesley.
 * Container environment variables are now made available to SSH root shells. If you login with SSH through a non-root account, then container environment variables are only made available if that user is a member of the `docker_env` group. Thanks to Bernard Potocki.
 * `add-apt-repository` is now installed by default. Closes GH-74.
 * Various minor fixes and contributions thanks to yebyen, John Eckhart, Christoffer Sawicki and Brant Fitzsimmons.

## 0.9.10 (release date: 2014-05-12)

 * Upgraded to Ubuntu 14.04 (Trusty). We will no longer release images based on 12.04.
   Thanks to contributions by mpeterson, Paul Jimenez, Santiago M. Mola and Kingdon Barrett.
 * Fixed a problem with my_init not correctly passing child processes' exit status. Fixes GH-45.
 * When reading environment variables from /etc/container_environment, the trailing newline (if any) is ignored. This makes commands like this work, without unintentially adding a newline to the environment variable value:

        echo my_value > /etc/container_environment/FOO

   If you intended on adding a newline to the value, ensure you have *two* trailing newlines:

        echo -e "my_value\n" > /etc/container_environment/FOO
 * It was not possible to use `docker run -e` to override environment variables defined in /etc/container_environment. This has been fixed (GH-52). Thanks to Stuart Campbell for reporting this bug.

## 0.9.9 (release date: 2014-03-25)

 * Fixed a problem with rssh. (Slawomir Chodnicki)
 * The `INITRD` environment variable is now set in the container by default. This prevents updates to the `initramfs` from running grub or lilo.
 * The `ischroot` tool in Ubuntu has been modified to always return true. This prevents updates to the `initscripts` package from breaking /dev/shm.
 * Various minor bug fixes, improvements and typo corrections. (Felix Hummel, Laurent Sarrazin, Dung Quang, Amir Gur)

## 0.9.8 (release date: 2014-02-26)

 * Fixed a regression in `my_init` which causes it to delete environment variables passed from Docker.
 * Fixed `my_init` not properly forcing Runit to shut down if Runit appears to refuse to respond to SIGTERM.

## 0.9.7 (release date: 2014-02-25)

 * Improved and fixed bugs in `my_init` (Thomas LÉVEIL):
   * It is now possible to enable the insecure key by passing `--enable-insecure-key` to `my_init`. This allows users to easily enable the insecure key for convenience reasons, without having the insecure key enabled permanently in the image.
   * `my_init` now exports environment variables to the directory `/etc/container_environment` and to the files `/etc/container_environment.sh`, `/etc/container_environment.json`. This allows all applications to query what the original environment variables were. It is also possible to change the environment variables in `my_init` by modifying `/etc/container_environment`. More information can be found in the README, section "Environment variables".
   * Fixed a bug that causes it not to print messages to stdout when there is no pseudo terminal. This is because Python buffers stdout by default.
   * Fixed an incorrectly printed message.
 * The insecure key is now also available in PuTTY format. (Thomas LÉVEIL)
 * Fixed `enable_insecure_key` removing already installed SSH keys. (Thomas LÉVEIL)
 * The baseimage-docker image no longer EXPOSEs any ports by default. The EXPOSE entries were originally there to enable some default guest-to-host port forwarding entries, but in recent Docker versions they changed the meaning of EXPOSE, and now EXPOSE is used for linking containers. As such, we no longer have a reason to EXPOSE any ports by default. Fixes GH-15.
 * Fixed syslog-ng not being able to start because of a missing afsql module. Fixes the issue described in [pull request 7](https://github.com/phusion/baseimage-docker/pull/7).
 * Removed some default Ubuntu cron jobs which are not useful in Docker containers.
 * Added the logrotate service. Fixes GH-22.
 * Fixed some warnings in `/etc/my_init.d/00_regen_ssh_host_keys.sh`.
 * Fixed some typos in the documentation. (Dr Nic Williams, Tomer Cohen)

## 0.9.6 (release date: 2014-02-17)

 * Fixed a bug in `my_init`: child processes that have been adopted during execution of init scripts are now properly reaped.
 * Much improved `my_init`:
   * It is now possible to run and watch a custom command, possibly in addition to running runit. See "Running a one-shot command in the container" in the README.
   * It is now possible to skip running startup files such as /etc/rc.local.
   * Shutdown is now much faster. It previously took a few seconds, but it is now almost instantaneous.
   * It ensures that all processes in the container are properly shut down with SIGTERM, even those that are not direct child processes of `my_init`.
 * `setuser` now also sets auxilliary groups, as well as more environment variables such as `USER` and `UID`.

## 0.9.5 (release date: 2014-02-06)

 * Environment variables are now no longer reset by runit. This is achieved by running `runsvdir` directly instead of through Debian's `runsvdir-start`.
 * The insecure SSH key is now disabled by default. You have to explicitly opt-in to use it.

## 0.9.4 (release date: 2014-02-03)

 * Fixed syslog-ng startup problem.

## 0.9.3 (release date: 2014-01-31)

 * It looks like Docker changed their Ubuntu 12.04 base image, thereby breaking our Dockerfile. This has been fixed.
 * The init system (`/sbin/my_init`) now supports running scripts during startup. You can put startup scripts `/etc/my_init.d`. `/etc/rc.local` is also run during startup.
 * To improve security, the base image no longer contains pregenerated SSH host keys. Instead, users of the base image are encouraged to regenerate one in their Dockerfile. If the user does not do that, then random SSH host keys are generated during container boot.

## 0.9.2 (release date: 2013-12-11)

 * Fixed SFTP support. Thanks Joris van de Donk!

## 0.9.1 (release date: 2013-11-12)

 * Improved init process script (`/sbin/my_init`): it now handles shutdown correctly. Previously, `docker stop` would not have any effect on `my_init`, causing the whole container to be killed with SIGKILL. The new init process script gracefully shuts down all runit services, then exits.

## 0.9.0 (release date: 2013-11-12)

 * Initial release
