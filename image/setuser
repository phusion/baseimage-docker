#!/usr/bin/python3
import sys, os, pwd

if len(sys.argv) < 3:
	sys.stderr.write("Usage: /sbin/setuser USERNAME COMMAND [args..]\n")
	sys.exit(1)

def abort(message):
	sys.stderr.write("setuser: %s\n" % message)
	sys.exit(1)

username = sys.argv[1]
try:
	user = pwd.getpwnam(username)
except KeyError:
	abort("user %s not found" % username)
os.initgroups(username, user.pw_gid)
os.setgid(user.pw_gid)
os.setuid(user.pw_uid)
os.environ['USER'] = username
os.environ['HOME'] = user.pw_dir
os.environ['UID']  = str(user.pw_uid)
try:
	os.execvp(sys.argv[2], sys.argv[2:])
except OSError as e:
	abort("cannot execute %s: %s" % (sys.argv[2], str(e)))
