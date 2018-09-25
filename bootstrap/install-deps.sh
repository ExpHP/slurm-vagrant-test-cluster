#!/usr/bin/env bash

# This takes a freshly-created archlinux/archlinux box and installs software.
#
# Due to archlinux's rolling distribution model, this is liable to break over time,
# but it was simply the easiest thing for me to set up. I can't get virtualbox to even
# find its kernel modules on arch, and I had trouble finding a stabler libvirt box.
#
# Ideally, for the least amount of headache, this should be run once, and the resulting
# image should be saved as a new box.

set -x

install_makepkg_repo() {
    # makepkg complains if run as root
    su $user <<EOF
git clone $1 $2
(
    cd $2
    makepkg --noconfirm -fsri
)
EOF
}

pacman --noconfirm --noprogressbar -Syyu
pacman --noconfirm --noprogressbar -S git vim binutils make fakeroot gcc
# pacman --noconfirm --noprogressbar -S autoconf automake libtool
pacman --noconfirm --noprogressbar -S expect

# aur tool
install_makepkg_repo https://github.com/actionless/pikaur $home/pikaur

pacman --noconfirm --noprogressbar -S openmpi
pikaur --noconfirm --noprogressbar -S munge

# current slurm PKGBUILD is no good
#pikaur --noconfirm --noprogressbar -S slurm-llnl
#install_makepkg_repo https://aur.archlinux.org/slurm-llnl.git $home/slurm-llnl
su $user <<'EOF'
git clone https://aur.archlinux.org/slurm-llnl.git ~/slurm-llnl
cd ~/slurm-llnl

git checkout cc619476ce9f212e01f920effd552e8940c06e8c
# SO MANY BUGS
git apply /vagrant/patch/slurm-llnl/*.patch

makepkg --noconfirm -fsri
if [[ $? -eq 0 ]]; then
  cd ~
  rm -rf slurm-llnl # save space
fi
EOF

