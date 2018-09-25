#!/usr/bin/bash

set -x

#-------------------------------------
# prepare-for-packaging.sh:
#
# The sad truth is, you can't just package up an image you booted through `vagrant up`
# and expect it to work.  Some changes occur inside the machine during `vagrant up`
# which must be undone.
#-------------------------------------

# We need to leave the back door open for vagrant so that it can ssh in during `vagrant up`.

edit_sshd_config() {
    python3 - "$@" <<'EOF'
import sys

PATH='/etc/ssh/sshd_config'
with open(PATH) as f:
    lines = list(f)

for (i, line) in reversed(list(enumerate(lines))):
    if line.strip().startswith(sys.argv[1]):
        del lines[i]

lines += [' '.join(sys.argv[1:]) + '\n']
with open(PATH, 'w') as f:
    f.writelines(lines)
EOF
}

edit_sshd_config PubKeyAuthentication yes
edit_sshd_config AuthorizedKeysFile %h/.ssh/authorized_keys
edit_sshd_config PermitEmptyPasswords no
# SO answer says to set 'no' here, but that prevents multi-machine setups from
# communicating with each other to share public keys.
edit_sshd_config PasswordAuthentication yes

# Authorize the insecure RSA key that vagrant uses to get in initially.
# vagrant automatically removes it shortly after its first login.
cat > $home/.ssh/authorized_keys << EOKEYS
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
EOKEYS
chmod 600 $home/.ssh/authorized_keys
chown -R $user:$user $home/.ssh/

# If this is left behind, it will be identical across all machines when multiple are produced
# by a single Vagrantfile, and as a result, 'vagrant up' will only connect to one of them
# after it boots all of them up.
rm /etc/machine-id
rm /var/lib/dbus/machine-id

# The following stuff is done in https://github.com/cgwalters/qcow2-to-vagrant.
# I don't know if it's necessary.

#sed -i 's,Defaults\\s*requiretty,Defaults !requiretty,' /etc/sudoers
#sed -i 's/.*UseDNS.*/UseDNS no/' /etc/ssh/sshd_config

# # Disable cloud-init
# if [[ $(gf exists "${rootdir}/etc/cloud") == "true" ]]; then
#     touch /etc/cloud/cloud-init.disabled
# fi
# rm -rf /etc/systemd/system/multi-user.target.wants/cloud-init*
# rm -rf /etc/systemd/system/multi-user.target.wants/cloud-final.service
# rm -rf /etc/systemd/system/multi-user.target.wants/cloud-config*

