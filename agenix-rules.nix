let
  bob = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1qMFeB5NvVqu+bwLG7B52srrE/NCfm9z3s8lN6SBCl";
  cooper = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8vdxG5iXS9qVo2U9FKlqLVcj+KhWCzbPsaok+MCOiP";
in
{
  "secrets/bob/users/tomas-password.age".publicKeys = [ bob ];
  "secrets/bob/users/root-password.age".publicKeys = [ bob ];

  "secrets/bob/tailscale/api-key.age".publicKeys = [ bob ];
  "secrets/bob/acme/env.age".publicKeys = [ bob ];
  "secrets/bob/nas/smb-credentials.age".publicKeys = [ bob ];
  "secrets/bob/readeck/env.age".publicKeys = [ bob ];
  "secrets/bob/healthchecks/env.age".publicKeys = [ bob ];
  "secrets/bob/prometheus/snmp-env.age".publicKeys = [ bob ];
  "secrets/bob/paperless/admin-password.age".publicKeys = [ bob ];
  "secrets/bob/paperless/env.age".publicKeys = [ bob ];
  "secrets/bob/navidrome/env.age".publicKeys = [ bob ];

  "secrets/bob/authelia/postgres-password.age".publicKeys = [ bob ];
  "secrets/bob/authelia/jwt-secret.age".publicKeys = [ bob ];
  "secrets/bob/authelia/session-secret.age".publicKeys = [ bob ];
  "secrets/bob/authelia/storage-encryption-key.age".publicKeys = [ bob ];
  "secrets/bob/authelia/users.age".publicKeys = [ bob ];
  "secrets/bob/authelia/oidc-hmac-secret.age".publicKeys = [ bob ];
  "secrets/bob/authelia/oidc-issuer-private-key.age".publicKeys = [ bob ];

  "secrets/bob/grafana/admin-password.age".publicKeys = [ bob ];
  "secrets/bob/grafana/secret-key.age".publicKeys = [ bob ];
  "secrets/bob/grafana/authelia-password.age".publicKeys = [ bob ];

  "secrets/cooper/users/tomas-password.age".publicKeys = [ cooper ];
  "secrets/cooper/users/root-password.age".publicKeys = [ cooper ];
}
