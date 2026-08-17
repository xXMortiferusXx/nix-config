# Gerät als Argument (vom Installer per temporaerer Config uebergeben).
# Default fuer normales Rebuild, wenn kein Geraet uebergeben wird.
{ device ? "/dev/nvme0n1", ... }: {
  disko.devices = {
    disk = {
      main = {
        inherit device;
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
            # Swap deaktiviert – wir nutzen nur ZRAM
            # swap = {
            #   size = "16G";
            #   content = {
            #     type = "swap";
            #     priority = 10;
            #     discardPolicy = "both";
            #   };
            # };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
