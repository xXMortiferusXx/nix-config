# Gerät als Argument (vom Installer per --argstr device übergeben).
# Default nur als Fallback für normales Rebuild, wenn kein Gerät übergeben wird.
{ device ? "/dev/nvme0n1", ... }: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
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
