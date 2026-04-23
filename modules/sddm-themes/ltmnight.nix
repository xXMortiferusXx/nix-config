{ pkgs }:                                                                                             
                                                                                                      
pkgs.stdenv.mkDerivation {                                                                            
  pname = "sddm-ltmnight-theme";                                                                      
  version = "1.2.4";                                                                                  
                                                                                                      
  src = pkgs.fetchFromGitHub {                                                                        
    owner = "xXMortiferusXx";                                                                         
    repo = "ltmnight-sddm-theme";                                                                     
    rev = "v1.2.4";                                                                                   
    sha256 = "sha256-QyCTVclRDqUtYJJwe3Gphrh9BgxMpOl+svEQCaNR+Iw=";                                   
  };                                                                                                  
                                                                                                      
  nativeBuildInputs = with pkgs; [                                                                    
    qt6.qttools                                                                                       
    qt6.wrapQtAppsHook                                                                                
  ];                                                                                                  
                                                                                                      
  dontWrapQtApps = true;                                                                              
                                                                                                      
  installPhase = ''                                                                                   
    mkdir -p $out/share/sddm/themes/ltmnight                                                          
    cp -aR . $out/share/sddm/themes/ltmnight/                                                         
                                                                                                      
    # Offizielle SDDM theme.conf mit expliziter Cursor-Definition                                     
    cat > $out/share/sddm/themes/ltmnight/theme.conf << EOF                                           
[SddmGreeterTheme]                                                                                    
Name=LTMNight                                                                                         
CursorTheme=Bibata-Modern-Classic                                                                     
CursorSize=24                                                                                         
EOF                                                                                                   
                                                                                                      
    # Deine bestehende Theme-Konfiguration                                                            
    cat > $out/share/sddm/themes/ltmnight/Themes/hyprltm.conf.user << EOF                             
[General]                                                                                             
Background="ltmnight"                                                                                 
PartialBlur="true"                                                                                    
FormPosition="center"                                                                                 
HideVirtualKeyboard="false"                                                                           
VirtualKeyboardAutoShow="false"                                                                       
EOF                                                                                                   
  '';                                                                                                 
}                                                                                                     
                                                         
