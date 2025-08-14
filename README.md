# Puppet Test Environment

This Vagrant environment sets up a complete Puppet infrastructure with a Puppet server and multiple agents for learning and testing purposes.

## Prerequisites

- VirtualBox installed
- Vagrant installed
- At least 6GB of free RAM (add 2GB per additional agent)

## Architecture

- **Puppet Server**: `puppet.localdomain` (192.168.56.10) - Ubuntu 24.04 with 4GB RAM
- **Puppet Agents**: By default, one agent is created:
  - `agent1.localdomain` (192.168.56.11) - Ubuntu 24.04 with 2GB RAM

Below is an ASCII diagram illustrating the structure of the Puppet Master (Server) and Agent (Slave) setup as provisioned by this Vagrantfile:

```text
         +------------------------+            +-----------------------------+
         |                        |            |                             |
         |  Puppet Master         |            |  Puppet Agent(s)            |
         |  (puppet.localdomain)  | <----------|  (agent1.localdomain,...)   |
         |  192.168.56.10         |            |  192.168.56.11+             |
         |                        |            |                             |
         +------------------------+            +-----------------------------+
                  ^                                           |
                  |                                           |
                  +-------------------------------------------+
                        (Puppet Code, Catalogs, Reports)

```

- The **Puppet Master** (Server) compiles and serves configuration catalogs to the agents.
- **Puppet Agents** periodically request their configuration from the master and apply it locally.
- Communication is secured via SSL certificates (autosigned for local development).

### What does the Vagrantfile do?

The provided `Vagrantfile` automates the setup of this environment:

- **Provisions one Puppet Master** (`puppet.localdomain`) and one or more Puppet Agents (`agent1.localdomain`, etc.) as VirtualBox VMs.
- **Configures networking** so all VMs are on a private network and can communicate.
- **Installs Puppet Server and Agent** packages at the specified version.
- **Sets up code syncing**: Puppet modules and manifests from your local project are synced into the master VM for live development.
- **Bootstraps configuration**: Handles SSL, autosigning, and environment variables for seamless agent-master communication.
- **Customizes shell and editor**: Copies `.vimrc` and sets up useful shell aliases for development.

This lets you quickly spin up a realistic Puppet infrastructure for testing, learning, or module development, all managed from a single Vagrantfile.

### Scaling Agents

You can easily create multiple agents by modifying the `NUM_AGENTS` variable in the Vagrantfile:

```ruby
NUM_AGENTS = 3  # Creates agent1, agent2, and agent3
```

Additional agents will be automatically assigned IP addresses in sequence:

- `agent2.localdomain` (192.168.56.12)
- `agent3.localdomain` (192.168.56.13)
- And so on...

## Quick Start

1. **Bring up the environment:**

   ```bash
   vagrant up
   ```

2. **Test the setup:**

   ```bash
   # SSH to agent
   vagrant ssh puppet-agent1

   # Run puppet agent (should work immediately)
   sudo puppet agent --test --noop

3. **For local development with VS Code:**

   ```bash
   # Edit Puppet code locally - changes sync automatically to VMs
   code manifests/ puppet-modules/
   ```

## Creating Test Manifests

### Simple Test Manifest

Create a basic manifest to test functionality:

```bash
# On puppet server - directory already exists via synced folder
sudo tee /etc/puppetlabs/code/environments/production/manifests/site.pp << 'EOF'
node 'agent1.localdomain' {
  file { '/tmp/puppet-test.txt':
    ensure  => present,
    content => "Hello from Puppet Server!\nManaged by Puppet\n",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  package { 'nginx':
    ensure => installed,
  }

  service { 'nginx':
    ensure => running,
    enable => true,
  }
}
EOF
```

### Apply the manifest

```bash
# On agent (remove --noop to actually apply changes)
sudo puppet agent --test
```

## Troubleshooting

### Connection Issues

If the agent can't connect to the server:

1. **Check DNS resolution:**

   ```bash
   nslookup puppet
   ping puppet.localdomain
   ```

2. **Verify puppet server is running:**

   ```bash
   # On puppet server
   sudo systemctl status puppetserver
   sudo netstat -tlnp | grep 8140
   ```

3. **Check firewall (if applicable):**

   ```bash
   sudo ufw status
   ```

### Certificate Issues

The environment uses autosign, so certificate issues should be rare. If you encounter problems:

1. **Check autosign configuration:**

   ```bash
   # On puppet server
   sudo cat /etc/puppetlabs/puppet/autosign.conf
   # Should show: *.localdomain
   ```

2. **If needed, clean certificates and retry:**

   ```bash
   # On agent
   sudo find /var/lib/puppet/ssl -type f -delete 2>/dev/null || true
   sudo find /etc/puppetlabs/puppet/ssl -type f -delete 2>/dev/null || true

   # On server (if autosign fails)
   sudo puppetserver ca clean --certname agent1.localdomain
   ```

3. **Regenerate certificates:**

   ```bash
   # On agent
   sudo puppet agent --test
   ```

## Configuration Files

### Key Configuration Locations

- **Puppet Server Config**: `/etc/puppetlabs/puppet/puppet.conf`
- **Manifests**: `/etc/puppetlabs/code/environments/production/manifests/`
- **Modules**: `/etc/puppetlabs/code/environments/production/modules/`
- **Agent Config**: `/etc/puppetlabs/puppet/puppet.conf`
- **Agent Logs**: `/var/log/puppetlabs/puppet/`


## Useful Commands

```bash
# Puppet commands
sudo puppet config print       # Show all configuration
sudo puppet resource user root # Show user resource
sudo puppet apply manifest.pp  # Apply local manifest
sudo facter                    # Show system facts

# Helpful aliases (automatically configured)
p                              # alias for 'puppet'
pp                             # alias for 'puppet apply'
pgt                            # alias for 'puppet agent -t'
```

## Resources

- [Puppet Documentation](https://puppet.com/docs/)
