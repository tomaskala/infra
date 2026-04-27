# infra

Configuration for my network infrastructure.

## Hosts

| Hostname | Device type | Operating system |
| ------------ | ------------------------- | ---------------- |
| `bob` | ASUS NUC 14 Pro | NixOS |
| `blacklodge` | Desktop computer | Pop!\_OS |
| `cooper` | Lenovo Thinkpad T14 Gen 2 | NixOS |
| `gordon` | MacBook Air M3 | MacOS |
| `hawk` | iPhone SE 2022 | iOS |
| `audrey` | MikroTik hAP ac lite TC | OpenWRT |
| `leland` | Synology NAS | Synology thingy |
| `bobby` | Steam Deck | SteamOS |

## Deployment

To define and deploy a machine (called `twinpeaks` in this example), do the following.

1. Put its configuration under `hosts/twinpeaks`.
2. Create an `outputs.nixosConfigurations.twinpeaks` block in `flake.nix`.
3. Start the machine and its SSH server to generate an SSH host key.
4. Obtain the host key.
   ```
   $ ssh-keyscan <ip-address>
   ```
5. Follow the instructions in the [secrets section](#secrets) to include any
   secrets.
6. Follow the [nixos-anywhere section](#nixos-anywhere) to install NixOS.

## Secrets

To add secrets for a machine, do the following.

1. Put the host key and any secrets inside `secrets.nix`.
2. Define all secrets.
   ```
   $ nix shell github:ryantm/agenix#agenix
   $ agenix -e secrets/secret.age
   ```
   Note that for secrets holding the user passwords (to be used with
   `config.users.users.<name>.hashedPasswordFile`), the content of the
   age-encrypted file should be the SHA-512 of the password. That is, create
   the secret as
   ```
   $ nix shell github:ryantm/agenix#agenix
   $ openssl passwd -6 -in <password-file> | agenix -e secrets/users/user.age
   ```

## nixos-anywhere

This section assumes we are using the
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere) tool to
install NixOS. More details can be found in their [quickstart guide](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md).

### NixOS installation while copying existing SSH host key

Copying an SSH host key from the previous installation is useful to ensure
that age secrets can be decrypted without having to re-encrypt them.

Run the following script in the root of the repository (taken from a nixos-anywhere
[example](https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/secrets.md#example-decrypting-an-openssh-host-key-with-pass)).
Don't forget to change the IP address!
```
#!/usr/bin/env bash

# Create a temporary directory.
temp=$(mktemp -d)

# Cleanup the temporary directory on exit.
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys.
install -d -m755 "$temp/etc/ssh"

# Decrypt your private key from the password store and copy it to the temporary directory.
pass ssh_host_ed25519_key > "$temp/etc/ssh/ssh_host_ed25519_key"

# Set the correct permissions so sshd will accept the key.
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

# Install NixOS to the host system with our secrets.
nix run github:nix-community/nixos-anywhere -- --extra-files "$temp" --flake '.#twinpeaks' --target-host root@<ip-address>
```

### NixOS installation without copying anything

If it's not necessary to transfer the SSH host key, simply run the following
```
nix run github:nix-community/nixos-anywhere -- --flake '.#twinpeaks' --target-host root@<ip-address>
```
