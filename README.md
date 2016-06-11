# The Hodor Assimilator and Package Distributer.

Hodor drags your workers where they need to be.

Hodor assimilates nodes and installs packages.

```
Usage:
  $ sh assimilate.sh Directory Hostname
```

Directory must start with a letter [A-Za-z].

Hostname is any DNS hostname or dotted quad,
as understood by ssh, scp, and rsync.

## What Happens:

* A recursive copy of the directory will be installed on the named host under /opt/hodor/.
* The named host will be 'assimilated' to run all installed packages.
* The named host will be rebooted.  Logs are kept under /opt/log/.

The packages are actually launched on reboot.
Any "boot" scripts matching this glob pattern
```
  [A-Za-z]*.boot.sh
```
will be executed by /bin/bash, running as root.

## Warnings:

* The assimilator overwrites /etc/rc.local
  on the target host.  The new /etc/rc.local
  will execute each .boot.sh file in each package.

* The assimilator overwrites root's crontab
  on the target host.  The new crontab will
  apt-get update & upgrade the target host every hour,
  and reboot the machine weekly on Sunday morning.

* There are no guarantees about the order of packages launching.

* Packages are launched as root.

* Packages may get shut down with no warning.
