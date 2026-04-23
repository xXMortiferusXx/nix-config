{ pkgs }:                                                                                             
                                                                                                      
pkgs.stdenv.mkDerivation {                                                                            
  pname = "sddm-ltmnight-theme";                                                                      
  version = "main";                                                                                  
                                                                                                      
  src = pkgs.fetchFromGitHub {                                                                        
    owner = "xXMortiferusXx";                                                                         
    repo = "ltmnight-sddm-theme";                                                                     
    rev = "main";                                                                                   
    sha256 = "sha256-to8+o0DgtrwR+pXUQy7+Fk+T3Zh8kKYqI552NAjVz/k=";                                                                                   
  };                                                                                                  
                                                                                                      
  nativeBuildInputs = with pkgs; [                                                                    
    qt6.qttools                                                                                       
    qt6.wrapQtAppsHook                                                                                
  ];                                                                                                  
                                                                                                      
  dontWrapQtApps = true;                                                                              
                                                                                                      
  installPhase = ''                                                                                   
    mkdir -p $out/share/sddm/themes/ltmnight                                                          
    cp -aR . $out/share/sddm/themes/ltmnight/                                                         
                                                                                                      
    # Offizielle SDDM theme.conf mit expliziter Cursor-Definition und GLSL Shader Aktivierung
    cat > $out/share/sddm/themes/ltmnight/theme.conf << EOF                                           
[SddmGreeterTheme]                                                                                    
Name=LTMNight                                                                                         
CursorTheme=Bibata-Modern-Classic                                                                     
CursorSize=24
BackgroundType=shader
Shader=background.qml
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
