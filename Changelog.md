## 0.9.9 (not yet released)

 * Fixed a problem with rssh. (Slawomir Chodnicki)

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
