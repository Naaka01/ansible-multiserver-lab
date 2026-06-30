# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.boot_timeout = 300

  # Provider VMware — défaut toutes VMs
  config.vm.provider "vmware_desktop" do |v|
    v.memory = 1024
    v.cpus   = 1
  end

  # ── CONTROL ──
  config.vm.define "control" do |control|
    control.vm.hostname = "control"
    control.vm.network "private_network", ip: "192.168.200.10"
    control.vm.provision "shell", inline: <<-SHELL
      apt-get update -y
      apt-get install -y ansible sshpass
    SHELL
  end

  # ── LB01 ──
  config.vm.define "lb01" do |lb|
    lb.vm.hostname = "lb01"
    lb.vm.network "private_network", ip: "192.168.200.11"
  end

  # ── WEB01 ──
  config.vm.define "web01" do |web|
    web.vm.hostname = "web01"
    web.vm.network "private_network", ip: "192.168.200.12"
  end

  # ── WEB02 ──
  config.vm.define "web02" do |web|
    web.vm.hostname = "web02"
    web.vm.network "private_network", ip: "192.168.200.13"
  end

  # ── DB01 ──
  config.vm.define "db01" do |db|
    db.vm.hostname = "db01"
    db.vm.network "private_network", ip: "192.168.200.14"
  end

  # ── WEB03 — autoscaling ──
  config.vm.define "web03" do |web|
    web.vm.hostname = "web03"
    web.vm.network "private_network", ip: "192.168.200.15"
  end
  
end