# Disko-Konfiguration fuer benny (SATA-Datentraeger).
# Geraet als Argument (vom Installer per --argstr device uebergeben).
# Default nur fuer normales Rebuild, wenn kein Geraet uebergeben wird.
{ device ? "/dev/sda", ... }: {
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
