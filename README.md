# Ansible Multi-Server Lab

This project is a practical lab to deploy and secure a small multi-server infrastructure with Ansible and Vagrant.

## Project Overview

The lab provisions and configures:

- 1 control node (`control`)
- 1 load balancer (`lb01`)
- 2 web servers (`web01`, `web02`)
- 1 database server (`db01`)
- 1 optional autoscaling web server (`web03`)

Main goals:

- Deploy Nginx on web servers
- Configure Nginx as a load balancer
- Deploy MySQL for application data
- Apply baseline security hardening (UFW, SSH hardening, Nginx headers)
- Demonstrate autoscaling behavior with `web03`

## Repository Structure

- `Vagrantfile` – VM definitions and networking
- `nginx.yml` – web server setup
- `loadbalancer.yml` – load balancer setup
- `database.yml` – MySQL setup
- `security.yml` – firewall and host hardening
- `autoscale.ps1` – PowerShell autoscaling script
- `ansible-multiserver_Lab.pdf` – project/lab documentation

## Lab Topology

- `control` → `192.168.200.10`
- `lb01` → `192.168.200.11`
- `web01` → `192.168.200.12`
- `web02` → `192.168.200.13`
- `db01` → `192.168.200.14`
- `web03` → `192.168.200.15` (autoscaling node)

## Prerequisites

- Vagrant
- VMware Desktop provider for Vagrant
- Ansible (installed automatically on `control` by Vagrant provisioning)
- PowerShell (for `autoscale.ps1`, optional)

## Quick Start

1. Start the infrastructure:

   ```bash
   vagrant up
   ```

2. SSH into the control node:

   ```bash
   vagrant ssh control
   ```

3. Run Ansible playbooks from the control node (using your inventory):

   ```bash
   ansible-playbook nginx.yml
   ansible-playbook loadbalancer.yml
   ansible-playbook database.yml
   ansible-playbook security.yml
   ```

## Playbook Roles

- `nginx.yml` installs and enables Nginx on web servers and writes a host-specific index page.
- `loadbalancer.yml` configures Nginx reverse proxy on `lb01` and forwards traffic to `web01`/`web02`.
- `database.yml` installs MySQL, creates `appdb`, and provisions `appuser`.
- `security.yml` applies firewall rules, Nginx security headers, and SSH hardening.

## Autoscaling

`autoscale.ps1` monitors average CPU load on `web01` and `web02`:

- scales up by starting `web03` and adding it to the load balancer when load is high
- scales down by removing and stopping `web03` when load is low

Update the `$LAB_PATH` variable in `autoscale.ps1` to match your local project path before running it.

## Notes

- The database playbook currently contains a demo password for lab usage (`AppPass123!`).
- For production usage, move secrets to Ansible Vault and enforce stronger secret management.
