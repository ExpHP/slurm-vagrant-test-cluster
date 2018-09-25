# vagrant archlinux slurm test cluster

A test environment for SLURM using vagrant to set up a cluster that:

* uses the `libvirt` provider
* is based on the `archlinux/archlinux` box

Using the `archlinux/archlinux` box was a terrible mistake in hindsight as it has no means of locking the versions of dependencies installed through pacman during provisioning; but I'm too exhausted at this point to do anything about it.

## Dependencies

```
sudo pacman -S vagrant libvirt dnsmasq qemu net-tools nfs-utils
vagrant plugin install pkg-config
vagrant plugin install vagrant-libvirt
vagrant box add archlinux-archlinux

# optional helper tools
# sudo pacman -S virt-viewer virt-manager
# sudo pikaur -S libguestfs
```

## An overview

This repo contains:

* A number of Vagrantfiles which enable/disable various parts of the setup process for QoL or testing purposes.
* A helper script `./use` for selecting the Vagrantfile.
* `bootstrap/`, containing scripts run by the virtual machines
* `common-defs.rb`, containing defines common to the Vagrantfiles (e.g. cluster setup)
* `save-box/`, a helper script for saving a box with pre-built dependencies. (see below)

### A complete start-up from scratch

The best way to test the Vagrantfile is to let it construct the entire setup from scratch.

```
# A Vagrantfile that does everything, creating a 3-machine cluster based on
# the archlinux/archlinux box and installing all dependencies.
./use full

vagrant up
```

If you see noticeable errors, try to fix them.  Keep a watchful eye; the scripts deliberately keep going on error because the bootstrap process takes long and it is in your best interest to see and fix as many problems as you can in each run cycle.

**Important:** If you need to make changes, anything host-specific should be in `config.sh`.  I.e. all three machines should still be identical after running `install-deps.sh`.

If it appeared to start up fine, then:

```
vagrant ssh controller
```

And once inside, verify the following things in turn:

`ssh server1` should not present any interactive prompt; i.e. it should not ask you to add the server to the list of known hosts, and it should not ask for a password. If it does, the password is `vagrant`, and you have some debugging to do, because these prompts will prevent `mpirun` from starting remote processes. (the `config.sh` script was supposed to remove these prompts through `ssh-copy-id`). Exit (Ctrl-D) back to `controller` once you confirm this.

`mpirun -np 1 --host controller hostname` should print `controller`.

`mpirun -np 2 --host server1,server2 hostname` should print `server1` and `server2`.

`slurmctld` should be running on `controller`.  If not, `sudo systemctl status slurmctld`.

`slurmd` should be running on `server1` and `server2`.  If not, `sudo systemctl status slurmd`.

Try `squeue` on `controller`.  It should print an empty table with just the header row.

Try submitting an sbatch.  **Beware: the home directory is not networked!** (and currently cannot be without causing SSH troubles).  For best results, do things in `~/data`.  Networked directories are defined in `common-defs.rb`, if you need to add more.

### Making a box with installed packages

Once everything is fine and dandy:

```
# A vagrantfile that only installs dependencies
./use init

vagrant up

# If you need to debug the setup, now's your chance!
# vagrant ssh

# Shut it down.
# Once you do this you may not be able to log back in through `vagrant up`,
# because the script at `bootstrap/prepare-for-packaging.sh` will have
# already burned some bridges.
vagrant halt

# Install it as a new vagrant box.
save-box/save-box

# Switch to a vagrantfile that uses the new box
./use fast

# Cross your fingers!
vagrant up
```

and enjoy your significantly faster VM boot times, assuming it works.  If not...

### Debugging the packaging process

If packaging doesn't work, there's two more Vagrantfiles to assist in debugging it so that you don't need to keep watching SLURM get built over and over.

```
# A vagrantfile that does nothing but prepare the base VM for packaging.
./use debug-pkg

vagrant up
vagrant halt

save-box/save-box

# A vagrantfile that creates a cluster with nothing installed,
# using the box saved from debug-pkg
./use debug-up
```

To verify that everything is good,

```
vagrant up
vagrant ssh controller
```

and from there, try to `ssh` into `server1` or `server2` (this time, you SHOULD get prompts for new fingerprints and password entry, since the config script was not run).  If you run into any issues along the way, the `save-box` and/or the `bootstrap/prepare-for-packaging` scripts may require your attention.

