# OpenClaw Infrastructure Walkthrough

This guide documents the complete setup process for deploying the OpenClaw agent infrastructure on a Hetzner VPS using Terraform, Docker, and Tailscale. Use this guide if you need to recreate the environment on a new device or server.

## 1. Preparing a New Device
If you are setting this up on a brand new device, you need to prepare the following:

### Dependencies to Install
1. **Terraform**: For provisioning the Hetzner VPS.
2. **Git & Git Bash**: For version control (use Git Bash on Windows).
3. **Make**: To run the `Makefile` deployment scripts.
4. **Tailscale**: For secure, private networking to the Web UI and SSH.

### Keys & Tokens Required
You will need to gather these tokens before starting:
- **Hetzner API Token**: For Terraform to provision the server.
- **Telegram Bot Token**: From `@BotFather` on Telegram.
- **AI API Keys**: Your Google AI Studio (Gemini) or Anthropic keys.
- **SSH Key**: Generate a new `id_ed25519` key if you don't have one, and add it to your `ssh-agent`:
  ```bash
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  ```

## 2. Infrastructure Setup (Repo 1: openclaw-terraform-hetzner)
You must set up the infrastructure first before deploying the docker configuration.

1. Create a `config/inputs.sh` file with your API tokens (Hetzner, GitHub).
2. Start your SSH agent so deployment scripts don't ask for your password repeatedly:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```
3. Provision the server:
   ```bash
   source config/inputs.sh
   make init
   make plan
   make apply
   ```
4. Verify Tailscale is connected (`make tailscale-status`), then lock down the server firewall by removing public SSH access in `inputs.sh` (`export TF_VAR_ssh_allowed_cidrs='[]'`) and running `make apply` again.

## 3. Configuration Setup (Repo 2: openclaw-docker-config)
Once the server is running, switch to the `openclaw-docker-config` repository. Your agent's settings (`openclaw.json`), personality (`SOUL.md`), skills (`skills-manifest.txt`), and Docker image definitions live here.

### Fixing Line Endings (Windows Only)
If cloning on Windows, Git converts shell scripts to `\r\n`. You must convert them back to Linux format before building the Docker image:
```bash
dos2unix docker/*.sh scripts/*.sh
```

### Building and Pushing Custom Images
1. Ensure your `GHCR_USERNAME` is correctly set in your environment.
2. Build the image and push it to your GitHub Container Registry:
   ```bash
   bash scripts/build-and-push.sh
   ```

## 4. Final Deployment (Back to Repo 1)
Once the server is provisioned and the Docker image is ready, go back to the `openclaw-terraform-hetzner` repository to deploy everything.

1. Setup your secrets in `secrets/openclaw.env`.
2. Push your config and secrets, then deploy:
   ```bash
   make push-env push-config deploy
   ```

## 5. Exposing the Gateway securely
We use **Tailscale Serve** to securely host the OpenClaw Web UI on your private Tailnet without exposing it to the public internet.
```bash
make ssh
sudo tailscale serve --bg 18789
```

**CORS & Proxies**: To ensure the Web UI works properly over Tailscale, your `openclaw.json` must include:
```json
"gateway": {
  "trustedProxies": ["172.16.0.0/12", "127.0.0.1", "::1"],
  "controlUi": {
    "allowedOrigins": ["https://your-tailnet-url.ts.net"]
  }
}
```

## 6. Telegram Bot Integration & Troubleshooting
To integrate the agent with Telegram and add it to groups, follow these steps:

1. **Create the Bot:** Talk to `@BotFather` on Telegram to create a bot and get the Token. Add it to `secrets/openclaw.env`.
2. **Turn off Privacy Mode:** In `@BotFather`, go to `Bot Settings` > `Group Privacy` > **Turn Off**. If this is on, the bot will silently ignore all group messages.
3. **Configure Allowlisting:** In `openclaw.json` (`channels.telegram`), set your User IDs in `allowFrom`. 
4. **Group Configuration:** If you add a `"groups"` block to `openclaw.json`, it enforces strict allowlisting. You must ensure:
   - Supergroup IDs always have a `-100` prefix (e.g., `-1003788752801`).
   - `"groupPolicy"` should be `"allowlist"`.
5. **Disable Heartbeat Spams:** To prevent the bot from waking up every 30 minutes, failing to compact memory, and spamming your API billing, disable the heartbeat in `openclaw.json`:
   ```json
   "agents": {
     "defaults": {
       "heartbeat": { "every": "0m" }
     }
   }
   ```
6. **Clearing Memory:** If the bot gets stuck with too much history (triggering API cap errors), type `/new` in the chat to drop the memory and start a fresh session.
