---
name: chezmoi-secrets
description: Use when adding, updating, or converting secrets in chezmoi-managed dotfiles. Triggers on "add a secret", "add an env var from 1password", "encrypt a secret with age", "convert secret from age to 1password" or vice versa.
---

# chezmoi Secrets

Manage secrets in chezmoi dotfiles using either 1Password (dynamic injection via templates) or age (encrypted files at rest in repo).

## Setup State

**1Password:** Configured and working.
- `~/.config/chezmoi/chezmoi.toml` has `[onepassword] prompt = true`
- CLI integration enabled in 1Password.app (biometric auth via Touch ID)
- Two accounts:
  - **Personal:** `my.1password.com` (stephen.m.cabrera@gmail.com)
  - **Work:** `userinterviews.1password.com` (stephen@userinterviews.com)

**Age:** Not yet installed. See setup section below.

**Shell config template:** `~/.local/share/chezmoi/dot_zshrc.tmpl` (already a `.tmpl` file).

## Approach 1: 1Password (Recommended for env vars)

Secrets live in 1Password only — never on disk or in the repo.

### Step 1: Find the op:// reference

```bash
# List items matching a name (must specify account if you have multiple)
op item list --account my.1password.com --format=json | jq -r '.[].title' | grep -i <name>
op item list --account userinterviews.1password.com --format=json | jq -r '.[].title' | grep -i <name>

# Get field IDs for an item
op item get "<Item Name>" --account my.1password.com --format=json \
  | jq '[.fields[] | {label: .label, id: .id, type: .type}]'
```

Fields with standard names (`password`, `username`) can be referenced by label.
Fields with generated IDs must use the ID directly (e.g. `26myhig3sfz5qtrbn6ywxudx4q`).

### Step 2: Add to dot_zshrc.tmpl

```bash
# Format:
export MY_SECRET="{{ onepasswordRead "op://VaultName/ItemName/field-or-id" "account.1password.com" }}"

# Personal account example:
export ANTHROPIC_API_KEY="{{ onepasswordRead "op://Shared/Anthropic/26myhig3sfz5qtrbn6ywxudx4q" "my.1password.com" }}"

# Work account example:
export SOME_WORK_SECRET="{{ onepasswordRead "op://Work Vault/Item/password" "userinterviews.1password.com" }}"
```

Add under the `# Environment Variables` section in `dot_zshrc.tmpl`.

### Step 3: Test and apply

```bash
# Test the reference resolves (shows first 20 chars only to avoid printing full key)
chezmoi execute-template '{{ onepasswordRead "op://Vault/Item/field" "account.1password.com" }}' | head -c 20

# Apply (run this in YOUR terminal — needs Touch ID, not from Claude Code)
chezmoi apply ~/.zshrc
```

## Approach 2: Age (For encrypted files at rest)

Best for non-env-var secrets: SSH keys, GPG keys, config files with embedded secrets.

### Setup (first time only)

```bash
# Install
brew install age

# Generate key — store the private key file safely, copy the public key
age-keygen -o ~/.config/chezmoi/key.txt
# Output: Public key: age1xxxxxxxx...

# Add to chezmoi config
cat >> ~/.config/chezmoi/chezmoi.toml <<'EOF'

encryption = "age"
[age]
  identity = "/Users/stephen/.config/chezmoi/key.txt"
  recipient = "age1xxxxxxxx..."   # paste your public key here
EOF

# IMPORTANT: Never commit key.txt to the repo
echo "key.txt" >> ~/.local/share/chezmoi/.gitignore
```

### Add an encrypted file

```bash
# Encrypts the file and adds it to chezmoi as encrypted_<filename>
chezmoi add --encrypt ~/.ssh/id_rsa
chezmoi add --encrypt ~/.config/someapp/credentials.json

# Edit an encrypted file (auto-decrypts, re-encrypts on save)
chezmoi edit ~/.ssh/id_rsa
```

## Converting Between Approaches

### 1Password → Age

Use when: you want to stop relying on 1Password CLI and store the secret encrypted in the repo instead.

```bash
# 1. Fetch the secret value from 1Password
op item get "Item Name" --account my.1password.com --fields password

# 2. Write it to a file
echo "sk-ant-..." > ~/.config/myapp/api_key

# 3. Add as an encrypted file via age
chezmoi add --encrypt ~/.config/myapp/api_key

# 4. Remove the onepasswordRead line from dot_zshrc.tmpl
# (the file will be decrypted to its destination by chezmoi apply instead)
```

### Age → 1Password

Use when: you want secrets centralized in 1Password instead of encrypted in the repo.

```bash
# 1. Decrypt and view the current secret
chezmoi cat ~/path/to/secret-file   # shows decrypted content

# 2. Store value in 1Password
op item create --category="API Credential" --title="MyApp" \
  --account my.1password.com \
  --vault="Shared" \
  credential="<value from step 1>"

# 3. Get the op:// reference
op item get "MyApp" --account my.1password.com --format=json \
  | jq '.fields[] | select(.label == "credential") | .reference'

# 4. Add onepasswordRead line to dot_zshrc.tmpl

# 5. Remove the encrypted file from chezmoi
chezmoi forget ~/path/to/secret-file
rm ~/.local/share/chezmoi/encrypted_<filename>
```

## Quick Reference

| | 1Password | Age |
|--|-----------|-----|
| Secret stored in | 1Password vault | Encrypted in git repo |
| Best for | Env vars, API keys | Files (SSH keys, certs) |
| Requires network | Yes (at apply time) | No |
| Auth | Touch ID via app | Key file on disk |
| Template syntax | `onepasswordRead "op://..."` | Automatic (no template needed) |
| New machine setup | Just `chezmoi apply` | Must copy `key.txt` securely |
