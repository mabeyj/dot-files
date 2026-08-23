#!/usr/bin/env python3
"""Diagnose sandbox networking and Chrome Crashpad prerequisites.

Run under several sandbox configurations to isolate which layer breaks what:

  A) sandbox --allow-project -- python3 sandbox-diag.py
       network-free: bwrap gets a private netns, Sandlock gets no net rules

  B) sandbox --allow-project --allow-https "GET example.com" -- python3 sandbox-diag.py
       network on, but NO --net-allow is generated

  C) sandbox --allow-project --allow-unsafe-https -- python3 sandbox-diag.py
       network on AND --net-allow present

  D) sandbox --allow-project --allow-localhost 9876 -- python3 sandbox-diag.py
       network-free plus loopback TCP

Reports exact errno for every failure, which is what distinguishes the layers:
Landlock denies bind/connect with EACCES, the seccomp blocklist denies with
EPERM, and the Sandlock supervisor refuses loopback connects with
ECONNREFUSED.

The port probed defaults to 9876 and can be overridden with $PROBE_PORT.
"""

import ctypes
import ctypes.util
import errno
import os
import socket
import struct
import sys
import threading

libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)

# x86_64 syscall numbers
NR_PTRACE = 101
NR_PRCTL = 157
NR_PROCESS_VM_READV = 310
PR_SET_PTRACER = 0x59616D61


def raw_syscall(nr, *args):
    """Run a syscall in a forked child so a denial cannot disturb the harness."""
    def fn():
        pid = os.fork()
        if pid == 0:
            ctypes.set_errno(0)
            rc = libc.syscall(ctypes.c_long(nr), *args)
            os._exit(0 if rc >= 0 else min(ctypes.get_errno(), 199))
        _, status = os.waitpid(pid, 0)
        if os.WIFSIGNALED(status):
            raise OSError(0, f"killed by signal {os.WTERMSIG(status)}")
        code = os.WEXITSTATUS(status)
        if code:
            raise OSError(code, os.strerror(code))
        return "permitted"
    return fn

PROBE_PORT = int(os.environ.get("PROBE_PORT", "9876"))


def show(label, fn):
    try:
        detail = fn()
        print(f"  {label:<44} OK    {detail if detail else ''}")
        return True
    except OSError as exc:
        name = errno.errorcode.get(exc.errno, "?")
        print(f"  {label:<44} FAIL  {name}/{exc.errno} ({exc.strerror})")
        return False
    except Exception as exc:
        print(f"  {label:<44} FAIL  {type(exc).__name__}: {exc}")
        return False


def bind_at(host, port, family=socket.AF_INET):
    def fn():
        s = socket.socket(family, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            s.bind((host, port))
            s.listen(1)
            return f"bound {s.getsockname()[:2]}"
        finally:
            s.close()
    return fn


def resolve(name):
    def fn():
        infos = socket.getaddrinfo(name, PROBE_PORT, proto=socket.IPPROTO_TCP)
        return ", ".join(sorted({str(i[4][0]) for i in infos}))
    return fn


def connect_permission():
    """Test connect permission independently of bind.

    Nothing listens on port 1, so the errno distinguishes the two cases:
    ECONNREFUSED means connect reached the stack and is permitted, EACCES
    means Landlock denied the connect itself.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    try:
        s.connect(("127.0.0.1", 1))
        return "unexpectedly connected"
    except ConnectionRefusedError:
        return "ECONNREFUSED -> connect is PERMITTED"
    finally:
        s.close()


def loopback_roundtrip():
    """What a browser test runner needs: a client connecting back to a
    local server.

    Binds the allowed port rather than an ephemeral one, so that a failure
    here reflects connect rather than bind.
    """
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("127.0.0.1", PROBE_PORT))
    server.listen(1)
    port = server.getsockname()[1]

    got = []
    t = threading.Thread(target=lambda: got.append(server.accept()), daemon=True)
    t.start()

    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.settimeout(5)
    try:
        client.connect(("127.0.0.1", port))
        t.join(timeout=5)
        if not got:
            raise TimeoutError("connected but accept never fired")
        return f"connected on port {port}"
    finally:
        client.close()
        server.close()


def scm_credentials():
    """What Chrome's Crashpad handshake needs."""
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
    print(f"pid={os.getpid()} nested={os.environ.get('SANDBOX_NESTED', '0')} "
          f"DISPLAY={os.environ.get('DISPLAY', '<unset>')}")

    print("\nname resolution files:")
    for path in ("/etc/hosts", "/etc/nsswitch.conf", "/etc/gai.conf",
                 "/etc/resolv.conf"):
        print(f"  {path:<44} {'present' if os.path.exists(path) else 'MISSING'}")

    print("\nname resolution:")
    show("getaddrinfo('localhost')", resolve("localhost"))

    print("\nTCP bind (Landlock denies with EACCES):")
    bind_ok = show(f"bind 127.0.0.1:{PROBE_PORT}",
                   bind_at("127.0.0.1", PROBE_PORT))
    show(f"bind 0.0.0.0:{PROBE_PORT}", bind_at("0.0.0.0", PROBE_PORT))
    show(f"bind [::1]:{PROBE_PORT}",
         bind_at("::1", PROBE_PORT, socket.AF_INET6))
    show("bind 127.0.0.1:0 (ephemeral)", bind_at("127.0.0.1", 0))

    print("\nloopback connect (Landlock denies with EACCES):")
    show("connect 127.0.0.1:1 (permission probe)", connect_permission)
    conn_ok = show(f"bind+connect roundtrip on {PROBE_PORT}", loopback_roundtrip)

    print("\ncrashpad prerequisites (all needed by CrashpadClient::StartHandler):")
    scm_ok = show("sendmsg SCM_CREDENTIALS", scm_credentials)
    ptracer_ok = show("prctl(PR_SET_PTRACER)",
                      raw_syscall(NR_PRCTL, PR_SET_PTRACER, -1, 0, 0, 0))
    show("ptrace(PTRACE_TRACEME)", raw_syscall(NR_PTRACE, 0, 0, 0, 0))
    show("process_vm_readv (EFAULT = permitted)",
         raw_syscall(NR_PROCESS_VM_READV, os.getpid(), None, 0, None, 0, 0))
    scm_ok = scm_ok and ptracer_ok

    print("\n" + "-" * 72)
    print(f"server can bind its port : {'yes' if bind_ok else 'NO'}")
    print(f"client can reach it      : {'yes' if conn_ok else 'NO'}")
    print(f"chrome crashpad can init : {'yes' if scm_ok else 'NO'}")
    verdict = bind_ok and conn_ok and scm_ok
    print(f"\nheadless Chrome test run viable: {'YES' if verdict else 'NO'}")
    return 0 if verdict else 1


if __name__ == "__main__":
    sys.exit(main())
