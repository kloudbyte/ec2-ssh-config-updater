# ec2-ssh-config-updater
Windows batch scripts that rebuild local SSH config every time your EC2 instance gets a new public IP
# EC2 SSH Config Updater

A small Windows batch script that rebuilds your local SSH config every time
your EC2 instance gets a new public IP — so VS Code's Remote-SSH extension
(and plain ssh) always connect the same way, without you manually editing
config files.

Why this exists

EC2 instances without an Elastic IP get a new public IP every time they're
stopped and started. That means your SSH config's HostName goes stale,
and tools like VS Code Remote-SSH fail with Permission denied or
Could not establish connection errors — even though your key and username
haven't changed.

This script solves that by:
- Using a fixed Host alias (my-ec2) that never changes, so VS Code
  always connects to the same alias regardless of the instance's current IP.
- Auto-detecting the .pem key file in the same folder — no need to
  hardcode a filename or edit the script when you rotate keys.
- Rebuilding the config from scratch each run, instead of doing
  fragile find-and-replace on the old file (which can silently produce
  duplicate or broken entries).
- Using an absolute path for the key file, so it resolves correctly
  no matter which directory VS Code's SSH process runs from.

Setup

1. Place this script (update-ec2-ip.bat) in your .ssh folder, e.g.
   C:\Users\<you>\.ssh\update-ec2-ip.bat
2. Place your EC2 .pem key file in the same folder.
3. Open the script and confirm these two lines match your setup:
   
   set "HOST_ALIAS=my-ec2"
   set "SSH_USER=ec2-user"
   
   Change SSH_USER if your AMI uses a different default user
   (e.g. ubuntu for Ubuntu AMIs).

Usage

Every time your EC2 instance gets a new public IP:

1. Double-click update-ec2-ip.bat
2. Enter the new IP when prompted (format X.X.X.X, e.g. 3.88.159.130).
3. That's it — your SSH config now points at the new IP under the same
   my-ec2 alias.

In VS Code:
- Ctrl+Shift+P → Remote-SSH: Connect to Host... → select my-ec2

In a terminal:

ssh my-ec2


What it generates

The script writes a clean SSH config block like this
(to .ssh\config, no file extension):

Host my-ec2
    HostName ec2-x-x-x-x.compute-1.amazonaws.com
    User ec2-user
    IdentityFile C:\Users\<you>\.ssh\your-key.pem
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new

It also backs up your previous config to config.bak before overwriting,
and clears any stale known_hosts entry for the new domain to avoid
host-key mismatch warnings after an IP change.

Notes

- Never commit your .pem key or generated config file to a public
  repository this repo's .gitignore already excludes them.
- This script only manages the SSH config; it doesn't touch AWS itself.
  You still need to start/stop your instance and grab its public IP from
  the AWS Console or CLI.

License

MIT — use, modify, and share freely.
