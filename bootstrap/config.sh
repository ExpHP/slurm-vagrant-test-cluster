#!/usr/bin/env bash

set -x

# setup config files in a VM that has all software installed

rm /etc/hosts
echo "192.168.0.100    controller" >> /etc/hosts
echo "192.168.0.101    server1" >> /etc/hosts
echo "192.168.0.102    server2" >> /etc/hosts

# we only generate the munge key once
if [[ ! -e /vagrant/munge.key ]]; then
  # not present on arch; not necessary since one is auto-generated
  # /usr/sbin/create-munge-key
  cp /etc/munge/munge.key /vagrant
fi
cp /vagrant/munge.key /etc/munge
chown munge /etc/munge/munge.key
# I don't know why this is here but it looks suspect
#chmod g-w /var/log
#chmod g-w /var/log/munge
sudo systemctl restart munge

# The original script just generated one private-pub pair and copied the pub key
#  into each machine's authorized_hosts, but this doesn't seem to work.
# If you make machines with identical keys and do ssh-copy-id, you'll see that
#  slightly different entries are added. (with differing hostnames, and only the
#  first 10% of the hash matches)
sudo -u $user ssh-keygen -t rsa -N "" -f $home/.ssh/id_rsa
for host in $hosts; do
  if [[ $(hostname) != $host ]]; then
    sudo -u $user /vagrant/send-key $host
  fi
done

cp /vagrant/slurm.conf /etc/slurm-llnl/slurm.conf

if [[ $(hostname) == $primary_host ]]; then
    systemctl enable slurmctld
    systemctl start slurmctld
else
    systemctl enable slurmd
    systemctl start slurmd
fi

