# azure-jumpbox-server

Standalone, fully network-isolated management VM (no public IP, no inbound NSG rule, no SSH path at all). Access only via `az vm run-command` (one-off) and Azure Serial Console (interactive) — both go through the Azure control plane, not the VNet data plane. This is deliberate, not a limitation to "fix" by adding a public IP, Azure Bastion, or an NSG exception — don't add those without the user explicitly asking, it defeats the point of the design.

## Depends on azure-virtual-network, but doesn't read its state

Takes `resource_group_name` and `app_subnet_id` as plain variables (from `terraform.tfvars`, gitignored), copied from that project's outputs — no `terraform_remote_state` data source. If the vnet project renames/recreates the App subnet, `terraform.tfvars` here goes stale and needs manual updating.

## Backend

Same shared Blob Storage backend as the other projects (provisioned by `azure-tfstate-bootstrap`). Key: `jumpbox/terraform.tfstate`.

## `subscription_id`

Same rule as every other project here: no default, set via `TF_VAR_subscription_id` (not `ARM_SUBSCRIPTION_ID` — see azure-virtual-network's CLAUDE.md for why).

## cloud-init / `custom_data`

Installs `mysql-client`, `postgresql-client` (apt) and `kubectl` (snap, `--classic`) on first boot. Changing `custom_data` **forces VM replacement** — that's fine, this VM is stateless/disposable by design, no data lives on it.

**`azure-cli` is not available as a snap package** — tried it, it broke the `snap:` cloud-init module and left the VM in `cloud-init status: error` (kubectl still installed fine, apt packages too; only the snap module failed on the azure-cli line). If Azure CLI is needed later, use the official apt-repo method (GPG key + `packages.microsoft.com` source), not snap.

## Reaching a future AKS cluster

`kubectl` is pre-installed for this reason, but two things are *not* set up yet and shouldn't be guessed at:
- **Credentials** (`kubeconfig` / `az aks get-credentials`) — needs Azure CLI, not installed (see above).
- **Network path** to the cluster's API server — depends on decisions the `azure-aks-cluster` project hasn't made yet (private vs. public API server, NSG rules). Don't add speculative NSG/route rules here or in the vnet project for this until that project actually exists and its design is known.

## Password rotation (Serial Console)

Never let the password pass through a chat/AI conversation. The pattern used and documented in the README: generate a random password locally, `chpasswd` it via `run-command`, write it to a local temp file (`~/jumpbox-password.txt`), read it there, save to a password manager, delete the file. Don't shortcut this by asking an AI session to display or "remember" the password.

## Git history was rewritten once — why

Early in this project's life, `terraform.tfstate` (containing a full RSA private key in plaintext — Terraform doesn't encrypt state) got committed, then "removed" with a normal follow-up commit. That does NOT remove it from git history — it stayed retrievable from the old commit on both public GitHub repos for months before it was caught and squashed away. Lesson: **never `git add` a `.tfstate` or `.tfvars` file, not even once, not even to "fix it in the next commit"** — the moment it's committed it's compromised, full history rewrite is the only real fix.

## Git remotes — push to both, every time

- `origin` → `github.com:xstratus/azure-jumpbox-server` (public)
- `jalcalaroot` → `github.com:jalcalaroot/azure-jumpbox-server` (public)

`git push origin main && git push jalcalaroot main` after every commit.
