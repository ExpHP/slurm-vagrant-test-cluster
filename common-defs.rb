#!/usr/bin/env ruby

# Used to generate multiple machines
@slurm_cluster = {
    :controller => {
        :hostname => "controller",
        :ipaddress => "192.168.0.100",
    },
    :server1 => {
        :hostname => "server1",
        :ipaddress => "192.168.0.101",
    },
    :server2 => {
        :hostname => "server2",
        :ipaddress => "192.168.0.102",
    },
}

# env vars for the scripts in bootstrap/
@env_vars = {
    :user => "vagrant",
    :home => "/home/vagrant",
    :hosts => "controller server1 server2",
    :primary_host => "controller",
}

def sync_dir(config, a, b)
  # default options are vers=3,udp.  On my archlinux machine this results in
  #    mount.nfs: requested NFS version or transport protocol is not supported
  # during vagrant up.
  #
  # The following flags are from jandrom's vagrantfile.
  config.vm.synced_folder(
    a, b,
    type: "nfs",
    mount_options: ['rw', 'vers=3', 'tcp', 'fsc', 'actimeo=1'],
  )
end

def setup_vagrant_dir(config)
  sync_dir(config, ".", "/vagrant")
end

def make_cluster(config)
  # use a minimal amount of RAM for each node to avoid overwhelming the host
  config.vm.provider "libvirt" do |v|
    v.memory = 256
    # have multiple CPUs for testing ntasks-per-node > 1
    v.cpus = 4
  end

  config.vm.network "private_network", type: "dhcp"
  @slurm_cluster.each_pair do |name, options|
    config.vm.define vm_name = name do |config|
      #config.vm.hostname = vm_name
      config.vm.hostname = "#{vm_name}"
      ip = options[:ipaddress]
      config.vm.network "private_network", ip: ip
    end
  end
  sync_dir(config, "./sync/tmp", "/tmp")
  sync_dir(config, "./sync/data", "/home/vagrant/data")
end
