 # BASH PROFILE
 export EDITOR=nvim
 export VISUAL=nvim
 export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
 export MANPAGER="nvim +Man!"
 export LESS="-R"

 export XDG_CONFIG_HOME="$HOME/.config"
 export XDG_DATA_HOME="$HOME/.local/share"
 export XDG_STATE_HOME="$HOME/.local/state"
 export XDG_CACHE_HOME="$HOME/.cache"

 [[ -f ~/.bashrc ]] && . ~/.bashrc 

 export XCURSOR_SIZE=24
 export MOZ_ENABLE_WAYLAND=1
 export GDK_BACKEND=wayland,x11
 export XDG_SESSION_DESKTOP=sway
 export XDG_SESSION_TYPE=wayland
 export XDG_CURRENT_DESKTOP=sway
 export PROTON_ENABLE_NGX_UPDATER=0

 export QT_QPA_PLATFORM="wayland;xcb"
 export ELECTRON_OZONE_PLATFORM_HINT=auto
 export _JAVA_AWT_WM_NONREPARENTING=1

 export DOTNET_CLI_TELEMETRY_OPTOUT=1

 
 # Nvidia
 export NVD_BACKEND=direct
 export GBM_BACKEND=nvidia-drm
 export __GLX_VENDOR_LIBRARY_NAME=nvidia
 export LIBVA_DRIVER_NAME=nvidia
 export WLR_NO_HARDWARE_CURSORS=1
 # ls -l /dev/dri/by-path/; resolved to cardN since wlroots splits on ':'
 export WLR_DRM_DEVICES=$(readlink -f /dev/dri/by-path/pci-0000:01:00.0-card)
 # Uncomment if things don't look right
 # export WLR_RENDERER=vulkan

 if [[ -z $WAYLAND_DISPLAY && -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    exec sway --unsupported-gpu
 fi
