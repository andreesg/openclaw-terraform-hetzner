# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do NOT** open a public GitHub issue
2. Use [GitHub Security Advisories](../../security/advisories/new) to report vulnerabilities privately
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if you have one)

We aim to respond to security reports within 48 hours and will work with you to understand and address the issue.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| < 1.0   | :x:                |

## Security Considerations

### Infrastructure Security

This project deploys cloud infrastructure. Please be aware of:

1. **API Credentials**
   - Never commit `config/inputs.sh` or `secrets/openclaw.env`
   - Use environment variables for sensitive data
   - Rotate API tokens regularly
   - Use separate tokens for different environments

2. **SSH Access**
   - The default configuration allows SSH from `0.0.0.0/0` (anywhere)
   - **Change this** in `config/inputs.sh` to your IP: `["YOUR_IP/32"]`
   - **Better:** Enable Tailscale VPN for private SSH access (see below)
   - Use SSH keys, never passwords
   - Keep your private keys secure

3. **Tailscale VPN (Recommended)**
   - Enable Tailscale for zero-trust, encrypted networking
   - Move SSH and gateway access off the public internet
   - Reduces attack surface significantly
   - Set `TF_VAR_enable_tailscale=true` in `config/inputs.sh`
   - See [docs/TAILSCALE.md](docs/TAILSCALE.md) for detailed setup
   - **Threat model improvements:**
     - SSH not exposed to internet scanners
     - Gateway accessible only via authenticated devices
     - End-to-end WireGuard encryption
     - No port forwarding or complex firewall rules needed

4. **Firewall Rules**
   - Review the firewall configuration in `infra/terraform/modules/hetzner-vps/main.tf`
   - Only open ports you need
   - Gateway binds to `127.0.0.1` by default (localhost only)
   - Use SSH tunneling or Tailscale Serve to access the gateway
   - With Tailscale: UDP port 41641 automatically opened for VPN

5. **Cloud-Init Scripts**
   - Review `infra/cloud-init/user-data.yml.tpl` before deploying
   - Runs with root privileges on first boot
   - Modifying this can affect server security
   - Tailscale installation uses official packages from Tailscale repository

6. **State Files**
   - Terraform state contains sensitive data
   - Use remote state backend (S3) for production
   - Encrypt state files at rest
   - Never commit `.tfstate` files

### Application Security

7. **OpenClaw Gateway**
   - Set strong `OPENCLAW_GATEWAY_TOKEN` in `secrets/openclaw.env`
   - Use SSH tunneling to access gateway (don't expose publicly)
   - Keep OpenClaw updated to latest version

8. **API Keys**
   - Claude/Anthropic API keys grant access to your account
   - Monitor usage and set spending limits
   - Use setup-token (subscription) instead of API keys when possible
   - Telegram bot tokens should be kept secret

### Tailscale Security

9. **Tailscale Auth Keys**
   - Generate auth keys at [login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys)
   - Use reusable, pre-authorized keys for easier deployment
   - Set expiration (90 days recommended) and rotate regularly
   - Never commit auth keys to version control
   - Stored as sensitive Terraform variable (`tailscale_auth_key`)
   - Enable MFA on your Tailscale account

### Cost Security

10. **Resource Limits**
   - Set up billing alerts in Hetzner Console
   - Start with small server types (cx23) for testing
   - Monitor resource usage regularly
   - Destroy test deployments when done (`make destroy`)

## Best Practices

### For Maintainers

- Review all PRs for security implications
- Run automated security scanning (tfsec, checkov)
- Keep dependencies updated
- Document security-relevant changes in release notes

### For Users

- Read the code before deploying to your infrastructure
- Start with a test deployment in a separate Hetzner project
- Use separate API credentials for testing vs production
- Enable two-factor authentication on your Hetzner account
- Regularly update to the latest version

## Known Security Considerations

### By Design

- Cloud-init runs with root privileges (standard for server provisioning)
- SSH access is initially broad (users should narrow this)
- Gateway uses API tokens for authentication (consider adding TLS)

### Out of Scope

This project does NOT provide:
- DDoS protection (use Hetzner's DDoS protection or Cloudflare)
- Automated security patching (you must update OpenClaw manually)
- Intrusion detection (consider adding fail2ban - planned for future release)
- Backup encryption (implement separately if needed)
- SSH hardening (disable password auth, root login - planned for future release)
- Automatic security updates (unattended-upgrades - planned for future release)

## Security Updates

Security updates will be released as patch versions and announced via:
- GitHub Security Advisories
- Release notes
- README badges (if applicable)

## Responsible Disclosure

We follow responsible disclosure practices:
- 90-day disclosure timeline for vulnerabilities
- Coordinated public disclosure after fix is available
- Credit given to reporters (if desired)
- CVE assignment for significant vulnerabilities (if applicable)

## Acknowledgments

We appreciate the security research community and all contributors who help keep this project secure.
