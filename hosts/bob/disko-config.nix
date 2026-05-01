{ pkgs, ... }:

# Mirrored ZFS boot volume.
# Source: https://lowtek.ca/roo/2025/nixos-with-mirrored-zfs-boot-volume/
let
  disk1 = "/dev/disk/by-id/nvme-KINGSTON_SFYRS1000G_50026B738272235A";
  boot1 = "/boot1";

  disk2 = ""; # TODO
  boot2 = "/boot2";

  zpoolName = "zroot";
in
{
  boot = {
    supportedFilesystems = [ "zfs" ];

    zfs = {
      package = pkgs.zfs_2_4;
      forceImportRoot = false;
    };

    loader = {
      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;
        efiSupport = true;
        copyKernels = true;
        device = "nodev";

        mirroredBoots = [
          {
            path = boot1;
            devices = [ disk1 ];
          }
          {
            path = boot2;
            devices = [ disk2 ];
          }
        ];
      };
    };
  };

  services.zfs.autoScrub.enable = true;

  disko.devices = {
    disk = {
      disk1 = {
        type = "disk";
        device = disk1;

        content = {
          type = "gpt";

          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = boot1;
                mountOptions = [
                  "umask=0077"
                  "nofail"
                ];
              };
            };

            swap = {
              size = "32G";

              content = {
                type = "swap";
                mountOptions = [ "nofail" ];
              };
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

      disk2 = {
        type = "disk";
        device = disk2;

        content = {
          type = "gpt";

          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = boot2;
                mountOptions = [
                  "umask=0077"
                  "nofail"
                ];
              };
            };

            swap = {
              size = "32G";

              content = {
                type = "swap";
                mountOptions = [ "nofail" ];
              };
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
        mode = "mirror";

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
