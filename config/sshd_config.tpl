# OpenClaw SSH Daemon Configuration
# ====================================
# Security hardening applied to the server via: make push-sshd-config
# Port is always 22 — access is controlled at the Hetzner firewall level
# via ssh_allowed_cidrs (e.g. restrict to Tailscale subnet 100.64.0.0/10)

Port 22
Protocol 2

PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes

X11Forwarding no
MaxAuthTries 3
LoginGraceTime 30

# Required for scp/sftp
Subsystem sftp /usr/lib/openssh/sftp-server
