{ config, pkgs, ... }:

{
  users.users.mortiferus.packages = with pkgs; [
    (makeDesktopItem {
      name = "ideamaker";
      desktopName = "ideaMaker";
      exec = "env QT_QPA_PLATFORM=xcb /home/mortiferus/Apps/ideaMaker.AppImage";
      icon = "/home/mortiferus/Apps/ideamaker.png";
      comment = "Raise3D Slicing Software";
      categories = [ "Graphics" ];
      terminal = false;
      type = "Application";
    })
  ];
}
