#!/usr/bin/python3

'''
Copyright (c) 2013-2015 Phusion Holding B.V.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
'''

import sys
import os
import pwd


def abort(message):
    sys.stderr.write("setuser: %s\n" % message)
    sys.exit(1)


def main():
    '''
    A simple alternative to sudo that executes a command as a user by setting
    the user ID and user parameters to those described by the system and then
    using execvp(3) to execute the command without the necessity of a TTY
    '''

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
    os.environ['UID'] = str(user.pw_uid)
    try:
        os.execvp(sys.argv[2], sys.argv[2:])
    except OSError as e:
        abort("cannot execute %s: %s" % (sys.argv[2], str(e)))

if __name__ == '__main__':

    if len(sys.argv) < 3:
        sys.stderr.write("Usage: /sbin/setuser USERNAME COMMAND [args..]\n")
        sys.exit(1)

    main()

