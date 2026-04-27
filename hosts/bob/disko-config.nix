let
  first = "/dev/nvme0n1";
  zpoolName = "zroot";
in
{
  disko.devices = {
    disk = {
      first = {
        type = "disk";
        device = first;

        content = {
          type = "gpt";

          partitions = {
            esp = {
              type = "EF00";
              size = "1G";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            swap = {
              size = "32G";
              content.type = "swap";
            };

            root = {
              size = "100%";

              content = {
                type = "zfs";
                pool = zpoolName;
              };
            };
          };
        };
      };
    };

    zpool = {
      ${zpoolName} = {
        type = "zpool";

        options = {
          ashift = "12";
          autotrim = "on";
        };

        rootFsOptions = {
          mountpoint = "none";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          relatime = "on";
        };

        datasets = {
          "system" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "system/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };

          "system/var" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "system/var/lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
            options.mountpoint = "legacy";
          };

          "system/var/lib/postgresql" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/postgresql";
            options = {
              mountpoint = "legacy";
              recordsize = "32K";
            };
          };

          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy";
              atime = "off";
              "com.sun:auto-snapshot" = "false";
            };
          };

          "data" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "data/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };

          "data/media" = {
            type = "zfs_fs";
            mountpoint = "/media";
            options.mountpoint = "legacy";
          };

          "reserved" = {
            type = "zfs_fs";
            options.mountpoint = "none";
            options.refreservation = "10G";
          };
        };
      };
    };
  };
}
