## 0.9.6 (release date: 2014-02-17)

 * Fixed a bug in `my_init`: child processes that have been adopted during execution of init scripts are now properly reaped.
 * Much improved `my_init`:
   * It is now possible to run and watch a custom command, possibly in addition to running runit. See "Running a one-shot command in the container" in the README.
   * It is now possible to skip running startup files such as /etc/rc.local.
   * Shutdown is not much faster. It previously took a few seconds, but it is now almost instantaneous.
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
