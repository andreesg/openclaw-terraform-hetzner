# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-02-08

### Added
- Initial release of OpenClaw Terraform infrastructure for Hetzner Cloud
- Modular Terraform structure (globals, environments, modules)
- hetzner-vps module for VPS provisioning with cloud-init
- Deployment automation via Makefile
- Bootstrap script for initial OpenClaw setup
- Deploy script for pulling and restarting containers
- Backup and restore functionality
- Status monitoring and log streaming
- SSH tunneling support for gateway access
- Claude subscription auth setup via setup-token
- Environment variable management (inputs.sh, openclaw.env)
- Comprehensive documentation (README, CONTRIBUTING, SECURITY)
- GitHub Actions CI/CD (Terraform validation, ShellCheck)
- Issue and PR templates

### Security
- Firewall configuration (SSH-only by default)
- UFW setup via cloud-init
- Secrets externalized to environment variables
- .gitignore for sensitive files

[Unreleased]: https://github.com/andreesg/openclaw-terraform-hetzner/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/andreesg/openclaw-terraform-hetzner/releases/tag/v1.0.0
