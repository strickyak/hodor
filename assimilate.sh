# Assimilate a node and add a package to it.
set -ex

case $# in
  2)
     SOURCE=$1
     TARGET=$2
     ;;
  *) echo "Usage:  $0  SourceDir  TargetHost" >&2
     exit 2 ;;
esac

P=$(basename $SOURCE)

# We always live in /opt/hodor.
ssh -n root@$TARGET 'mkdir -p /opt/hodor /opt/hodor/_OLD_'
# Copy the source recursively into /opt/hodor, keeping the dir name.
ssh -n root@$TARGET "cd /opt/hodor; mv $P _OLD_/$P.$$.old || true"
rsync -zav $SOURCE/ "root@$TARGET:/opt/hodor/$P/"

# Reset rc.local to boot all .boot.sh files at boot time.
# Logs go in /opt/log/hodor*
ssh root@$TARGET 'cat >/etc/rc.local' <<\~~~
#!/bin/bash
export PATH="/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
T=$(date +/opt/log/hodor-%Y-%m-%d-%H%M%S)
mkdir -p $T

exec </dev/null >$T/boot.log 2>&1
set -x

for x in /opt/hodor/[a-z]*/[a-z]*.boot.sh
do
  B=$(basename "$x")
  D=$(basename $(dirname "$x"))
  ( cd /opt/hodor/$D ; bash -x "$x" ) >$T/$D.$B.log 2>&1 &
  sleep 1
done
~~~

# Install a crontab to update and upgrade hourly,
# and to reboot on Sunday mornings.
R=$(python -c 'import random; print int(random.random()*40+15)')
ssh root@$TARGET 'crontab -' <<~~~
# m h  dom mon dow   command
0 * * * * PATH="\$PATH:/usr/sbin:/sbin" date   >>/tmp/apt.log 2>&1
2 * * * * PATH="\$PATH:/usr/sbin:/sbin" apt-get -q -y update   >>/tmp/apt.log 2>&1
5 * * * * PATH="\$PATH:/usr/sbin:/sbin" apt-get -q -y upgrade   >>/tmp/apt.log 2>&1
$R 11 * * 7 PATH="\$PATH:/usr/sbin:/sbin" shutdown -r now   >>/tmp/apt.log 2>&1
~~~

# The only way we start jobs is by rebooting the node.
ssh -n root@$TARGET 'sync; sync; sync; shutdown -r now'
