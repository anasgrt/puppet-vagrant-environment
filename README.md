# Puppet Test Environment

This Vagrant environment sets up a complete Puppet infrastructure with a Puppet server and multiple agents for learning and testing purposes.

## Architecture

- **Puppet Server**: `puppet.localdomain` (192.168.56.10) - Ubuntu 24.04 with 4GB RAM
- **Puppet Agents**: By default, one agent is created:
  - `agent1.localdomain` (192.168.56.11) - Ubuntu 24.04 with 2GB RAM

### Scaling Agents

You can easily create multiple agents by modifying the `NUM_AGENTS` variable in the Vagrantfile:

```ruby
NUM_AGENTS = 3  # Creates agent1, agent2, and agent3
```

Additional agents will be automatically assigned IP addresses in sequence:

- `agent2.localdomain` (192.168.56.12)
- `agent3.localdomain` (192.168.56.13)
- And so on...

## Prerequisites

- VirtualBox installed
- Vagrant installed
- At least 6GB of free RAM (add 2GB per additional agent)

## Quick Start

1. **Bring up the environment:**

   ```bash
   vagrant up
   ```

2. **For local development with VS Code:**

   ```bash
   # Edit Puppet code locally - changes sync automatically to VMs
   code manifests/ puppet-modules/
   ```

3. **The environment is ready to use!**

   The Vagrantfile automatically:
   - Configures DNS resolution in `/etc/hosts`
   - Sets up autosign for `*.localdomain` certificates
   - Runs the initial puppet agent connection
   - Configures proper PATH and aliases

4. **Test the setup:**

   ```bash
   # SSH to agent
   vagrant ssh puppet-agent1

   # Run puppet agent (should work immediately)
   sudo puppet agent --test --noop
   ```

## Detailed Setup Steps

### Network Configuration

The Vagrantfile configures a private network allowing the VMs to communicate:

- Puppet Server: `192.168.56.10`
- Puppet Agent: `192.168.56.11`

### Expected Output

When everything is working correctly, you should see:

```text
Info: Using environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Notice: Requesting catalog from puppet:8140 (192.168.56.10)
Notice: Catalog compiled by puppet.localdomain
Info: Applying configuration version '1752692125'
Notice: Applied catalog in 0.01 seconds
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

## Puppet Agent Initial Run Process Flow

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          PUPPET AGENT RUN PROCESS                               │
│                         (When state.yaml gets created)                          │
└─────────────────────────────────────────────────────────────────────────────────┘

    AGENT (192.168.56.11)                    PUPPET SERVER (192.168.56.10)
    ┌─────────────────┐                      ┌─────────────────────────────┐
    │ agent1.local    │                      │     puppet.local            │
    │                 │                      │                             │
    └─────────────────┘                      └─────────────────────────────┘
            │                                               │
            │                                               │
    ┌───────▼────────┐                                      │
    │ 1. START RUN   │                                      │
    │ puppet agent   │                                      │
    │ --test         │                                      │
    └───────┬────────┘                                      │
            │                                               │
            │ ── SSL Certificate Check ──────────────────▶  │
            │                                               │
            │ ◀────── Certificate Valid ─────────────────── │
            │                                               │
    ┌───────▼────────┐                                      │
    │ 2. REQUEST     │ ── "Send me catalog for" ────────▶   │
    │ CATALOG        │    "agent1.localdomain"              │
    └───────┬────────┘                              ┌───────▼────────-┐
            │                                       │ 3. COMPILE      │
            │                                       │ CATALOG         │
            │                                       │ - Read manifests│
            │                                       │ - Apply facts   │
            │                                       │ - Generate code │
            │ ◀─── Compiled Catalog ─────────────── │                 │
            │      (JSON/PSON format)               └───────┬────────-┘
            │                                               │
    ┌───────▼────────┐                                      │
    │ 4. RECEIVE &   │                                      │
    │ PARSE CATALOG  │                                      │
    └───────┬────────┘                                      │
            │                                               │
    ┌───────▼────────┐                                      │
    │ 5. APPLY       │                                      │
    │ CATALOG        │                                      │
    │ - Create files │                                      │
    │ - Install pkgs │                                      │
    │ - Start svc    │                                      │
    └───────┬────────┘                                      │
            │                                               │
      ██████▼██████                                         │
      ██            ██  ◀── THIS IS WHEN state.yaml         │
      ██  CREATE    ██      IS CREATED!                     │
      ██ state.yaml ██                                      │
      ██            ██  Location:                           │
      ████████████████  /var/cache/puppet/state/state.yaml  │
            │                                               │
    ┌───────▼────────┐                                      │
    │ 6. SEND REPORT │ ─── Report Status ──────────────▶    │
    │ (Optional)     │     (Success/Failure)                │
    └───────┬────────┘                              ┌───────▼────────┐
            │                                       │ 7. LOG REPORT  │
            │                                       │ (Optional)     │
    ┌───────▼────────┐                              └────────────────┘
    │ 8. COMPLETE    │                                      │
    │ "Applied       │                                      │
    │ catalog in     │                                      │
    │ 0.01 seconds"  │                                      │
    └────────────────┘                                      │

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              IMPORTANT NOTES                                    │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│ ✅ state.yaml is created ONLY after successful catalog application              │
│                                                                                 │
│ ❌ state.yaml is NOT created if:                                                │
│    • Certificate is not signed (autosign should handle this automatically)     │
│    • Network connectivity fails                                                 │
│    • Catalog compilation errors                                                 │
│    • Agent fails to apply catalog                                               │
│                                                                                 │
│ 📄 state.yaml contains:                                                         │
│    • Last run timestamp                                                         │
│    • Configuration version                                                      │
│    • Environment used                                                           │
│    • Puppet version                                                             │
│    • Transaction completion status                                              │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘

CONSOLE OUTPUT MAPPING:
┌─────────────────────────────────────────────────────────────────────────────────┐
│ "Info: Downloaded certificate..."           │  Steps 1-2                        │
│ "Notice: Requesting catalog from puppet..."  │  Step 2                          │
│ "Notice: Catalog compiled by puppet..."      │  Step 3                          │
│ "Info: Applying configuration version..."    │  Step 5 (start)                  │
│ "Info: Creating state file..."               │  ██ state.yaml creation ██       │
│ "Notice: Applied catalog in X seconds"       │  Step 8                          │
└─────────────────────────────────────────────────────────────────────────────────┘
```
