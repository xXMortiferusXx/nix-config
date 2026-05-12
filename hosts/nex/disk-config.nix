{ ... }: {
  disko.devices = {
    disk = {
      main = {
        # Hier wird das Device fest definiert, damit der Fehler 'attribute device missing' verschwindet
        device = "/dev/nvme0n1"; 
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "16G";
              content = {
                type = "swap";
                priority = 10;
                discardPolicy = "both";
                # resumeDevice ist entfernt für reinen RAM-Backup-Swap
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; 
                subvolumes = {
                  "/root" = { 
                    mountpoint = "/"; 
                    mountOptions = [ "compress=zstd" "noatime" ]; 
                  };
                  "/home" = { 
                    mountpoint = "/home"; 
                    mountOptions = [ "compress=zstd" "noatime" ]; 
                  };
                  "/nix" = { 
                    mountpoint = "/nix"; 
                    mountOptions = [ "compress=zstd" "noatime" ]; 
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
