let
  bob = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1qMFeB5NvVqu+bwLG7B52srrE/NCfm9z3s8lN6SBCl";
  cooper = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8vdxG5iXS9qVo2U9FKlqLVcj+KhWCzbPsaok+MCOiP";
  gordon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzFx62uD/5YWWOjLV5yVTTEDs2bHBM/j4yxndKzVotF";
in
{
  "secrets/bob/users/tomas.age".publicKeys = [
    bob
    gordon
  ];
  "secrets/bob/users/root.age".publicKeys = [
    bob
    gordon
  ];
  "secrets/bob/tailscale-api-key.age".publicKeys = [
    bob
    gordon
  ];
  "secrets/bob/nas-smb-credentials.age".publicKeys = [
    bob
    gordon
  ];

  "secrets/bob/authelia/postgres-password.age".publicKeys = [
    bob
    gordon
  ];
  "secrets/bob/authelia/jwt-secret.age".publicKeys = [
    bob
    gordon
  ];
  "secrets/bob/authelia/session-secret.age".publicKeys = [
    bob
    gordon
  ];
  "secrets/bob/authelia/storage-encryption-key.age".publicKeys = [
    bob
    gordon
  ];
  "secrets/bob/authelia/users.age".publicKeys = [
    bob
    gordon
  ];
  "secrets/bob/authelia/oidc-hmac-secret.age".publicKeys = [
    bob
    gordon
  ];
  "secrets/bob/authelia/oidc-issuer-private-key.age".publicKeys = [
    bob
    gordon
  ];

  "secrets/bob/tandoor-secret-key.age".publicKeys = [
    bob
    gordon
  ];

  "secrets/users/cooper/tomas.age".publicKeys = [ cooper ];
  "secrets/users/cooper/root.age".publicKeys = [ cooper ];

  "secrets/other/gordon/work-ssh-config.age".publicKeys = [ gordon ];
}
