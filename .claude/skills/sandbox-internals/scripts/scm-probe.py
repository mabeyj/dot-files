#!/usr/bin/env python3
"""Minimal reproducer for the headless Chrome crash under sandlock.

Chrome's Crashpad client hands its handler process a credentials-bearing
UNIX socket (crashpad's UnixCredentialSocket). If sending SCM_CREDENTIALS
fails, CrashpadClient::StartHandler() returns false and Chrome's
CHECK(result) in crashpad_linux.cc fires IMMEDIATE_CRASH() -- an int3/ud2
pair, i.e. SIGTRAP (exit 133) with no log output at all.

Run this under each sandbox configuration to find which layer denies it:

    python3 scm-probe.py                      # on the host: expect all OK
    bwrap ... -- python3 scm-probe.py         # bwrap only:  expect all OK
    sandbox -- python3 scm-probe.py           # bwrap+sandlock: SCM_CREDENTIALS fails

Exits non-zero if SCM_CREDENTIALS is denied, so it can gate a bisection.
"""

import os
import socket
import struct
import sys


def check(label, fn):
    try:
        detail = fn()
        print(f"  {label:<36} OK   {detail}")
        return True
    except Exception as exc:
        print(f"  {label:<36} FAIL {type(exc).__name__}: {exc}")
        return False


def plain_sendmsg():
    a, b = socket.socketpair(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        a.sendmsg([b"hello"])
        return f"received {b.recv(5)!r}"
    finally:
        a.close()
        b.close()


def passcred_sockopt():
    a, b = socket.socketpair(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        a.setsockopt(socket.SOL_SOCKET, socket.SO_PASSCRED, 1)
        b.setsockopt(socket.SOL_SOCKET, socket.SO_PASSCRED, 1)
        return "SO_PASSCRED set on both ends"
    finally:
        a.close()
        b.close()


def scm_rights():
    a, b = socket.socketpair(socket.AF_UNIX, socket.SOCK_STREAM)
    fd = os.open("/dev/null", os.O_RDONLY)
    try:
        a.sendmsg([b"x"], [(socket.SOL_SOCKET, socket.SCM_RIGHTS,
                            struct.pack("i", fd))])
        _, anc, _, _ = b.recvmsg(1, socket.CMSG_SPACE(4))
        return f"{len(anc)} ancillary message(s)"
    finally:
        os.close(fd)
        a.close()
        b.close()


def scm_credentials():
    """The operation Crashpad depends on."""
    a, b = socket.socketpair(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        b.setsockopt(socket.SOL_SOCKET, socket.SO_PASSCRED, 1)
        creds = struct.pack("3i", os.getpid(), os.getuid(), os.getgid())
        a.sendmsg([b"x"], [(socket.SOL_SOCKET, socket.SCM_CREDENTIALS, creds)])
        _, anc, _, _ = b.recvmsg(1, socket.CMSG_SPACE(12))
        return f"{len(anc)} ancillary message(s)"
    finally:
        a.close()
        b.close()


def main():
    print(f"pid={os.getpid()} uid={os.getuid()} gid={os.getgid()}")
    print("unix socket capabilities:")
    check("plain sendmsg", plain_sendmsg)
    check("SO_PASSCRED sockopt", passcred_sockopt)
    check("sendmsg SCM_RIGHTS", scm_rights)
    ok = check("sendmsg SCM_CREDENTIALS", scm_credentials)

    print()
    if ok:
        print("RESULT: SCM_CREDENTIALS allowed -- Chrome's Crashpad init should work.")
        return 0
    print("RESULT: SCM_CREDENTIALS DENIED -- Chrome will SIGTRAP (exit 133) here.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
