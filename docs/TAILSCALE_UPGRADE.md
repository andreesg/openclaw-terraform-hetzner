# Adding Tailscale to an Existing OpenClaw Installation

> **For new deployments**, set `TF_VAR_enable_tailscale=true` in `config/inputs.sh` before `make apply` — cloud-init handles installation automatically. See [TAILSCALE.md](TAILSCALE.md).

This guide covers adding Tailscale to a VPS that was deployed without it.

---

## Step 1: Get your auth key (optional but recommended)

Generate a reusable, pre-authorized key at <https://login.tailscale.com/admin/settings/keys>

Add it to `config/inputs.sh`:

```bash
export TF_VAR_tailscale_auth_key="tskey-auth-xxxxxxxxxxxxx"
source config/inputs.sh
```

---

## Step 2: Install Tailscale on the running server

```bash
make tailscale-install
```

This installs Tailscale, starts `tailscaled`, and authenticates with your auth key (if set).

---

## Step 3: Verify

```bash
make tailscale-status   # should show your node as connected
make tailscale-ip       # prints your Tailscale IP (e.g. 100.64.1.5)
```

---

## Step 4: Update Terraform (open Tailscale UDP port)

Edit `config/inputs.sh`:

```bash
export TF_VAR_enable_tailscale=true
source config/inputs.sh
```

Then:

```bash
make plan   # should show: + hcloud_firewall rule for UDP 41641
make apply
```

> **Note:** `make apply` only updates the Hetzner cloud-level firewall. UFW inside the server was already updated by `make tailscale-install`. This step just makes the Terraform state match reality.

---

## Step 5: (Optional) Access dashboard via Tailscale

By default the gateway is only reachable via `make tunnel` (SSH port forwarding). With Tailscale you can expose it as a private HTTPS endpoint accessible from any device on your tailnet.

**5a.** Add to your `openclaw.json` (in your config repo):

```json
"gateway": {
  "auth": {
    "allowTailscale": true
  }
}
```

Push it: `make push-config`

**5b.** Enable **Tailscale Serve** (not Funnel) in the [Tailscale admin console](https://login.tailscale.com/admin/dns) under the DNS/HTTPS section.

**5c.** On the server, set up the serve proxy:

```bash
make ssh
sudo tailscale serve --bg 18789
sudo tailscale serve status
```

The dashboard will be available at `https://openclaw-prod.<tailnet>.ts.net` from any of your Tailscale devices — no SSH tunnel needed.

> **Note:** Enable **Serve** only, not **Funnel**. Funnel exposes the service to the public internet, which defeats the purpose of using Tailscale.

---

## Step 6: (Optional) Restrict SSH to Tailscale only

Once Tailscale is working, you can remove public SSH access entirely by restricting it to the Tailscale CGNAT subnet:

```bash
# In config/inputs.sh:
export TF_VAR_ssh_allowed_cidrs='["100.64.0.0/10"]'
source config/inputs.sh
make apply
```

**Tradeoff**: If Tailscale goes down, you lose SSH access. Use the Hetzner web console as fallback. To recover: set `ssh_allowed_cidrs` back to `["0.0.0.0/0"]` and re-apply.

---

## Troubleshooting

### Tailscale not authenticating

```bash
make tailscale-up
```

Follow the URL printed in the output.

### UFW not showing Tailscale rule

```bash
make ssh
sudo ufw status numbered
sudo ufw allow 41641/udp comment 'Tailscale'
```
