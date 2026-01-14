#!/bin/sh

export GDK_SCALE=2  
export GTK_IM_MODULE=Maliit 
export GTK_IM_MODULE_FILE=/home/phablet/.config/min.pparent/immodules.cache 
export GDK_BACKEND=x11 
export DISABLE_WAYLAND=1 
export DCONF_PROFILE=/nonexistent
export XDG_CONFIG_HOME=/home/phablet/.config/min.pparent/
export XDG_DATA_HOME=/home/phablet/.local/share/min.pparent/
export XDG_DESKTOP_DIR=/home/phablet/.config/min.pparent/
export LD_LIBRARY_PATH=$PWD/lib/aarch64-linux-gnu/


utils/mkdir.sh /home/phablet/.config/min.pparent/
echo "\"$PWD/lib/aarch64-linux-gnu/gtk-3.0/3.0.0/immodules/im-maliit.so\""  > /home/phablet/.config/min.pparent/immodules.cache 
echo  "\"Maliit\" \"Maliit Input Method\" \"maliit\" \"\" \"en:ja:ko:zh:*\""  >> /home/phablet/.config/min.pparent/immodules.cache 

echo 'XDG_DESKTOP_DIR="/home/phablet/.cache/min.pparent/downloads/"'> /home/phablet/.config/min.pparent/user-dirs.dirs

if [ "$DISPLAY" = "" ]; then
    i=0
    while [ -e "/tmp/.X11-unix/X$i" ] ; do 
        i=$(( i + 1 ))
    done
    i=$(( i - 1 ))
    display=":$i"
    export DISPLAY=$display
fi

export PATH=$PWD/bin:$PATH
utils/mkdir.sh /home/phablet/.cache/min.pparent/

scale=$(./utils/get-scale.sh 2>/dev/null )


dpioptions="--high-dpi-support=1 --force-device-scale-factor=$scale --grid-unit-px=$GRID_UNIT_PX"
sandboxoptions="--no-sandbox"
gpuoptions="--use-gl=egl --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --enable-features=UseSkiaRenderer,VaapiVideoDecoder --disable-frame-rate-limit --disable-gpu-vsync --enable-oop-rasterization"

###################################################
# Handle customUserAgent
####################################################
CONFIGFILE="/home/phablet/.config/min.pparent/Min/settings.json"
utils/mkdir.sh /home/phablet/.config/min.pparent/Min/
UA="Mozilla/5.0 (Linux; Ubuntu 24.04 like Android 9) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36"
newjson="{\"filtering\":{\"blockingLevel\":2,\"contentTypes\":[],\"exceptionDomains\":[]},\"updateNotificationsEnabled\":false,\"collectUsageStats\":false,\"useSeparateTitlebar\":true,\"customUserAgent\":\"$UA\"}"
printf '%s\n' "$newjson" > "$CONFIGFILE"


#Open a dummy qt gui app to realease lomiri from its waiting
( utils/sleep.sh; $PWD/bin/xdg-open )&
( utils/filedialog-deamon.sh $$ )&

initpwd=$PWD
utils/mkdir.sh /home/phablet/.cache/min.pparent/downloads/
cd /home/phablet/.cache/min.pparent/downloads/

export HOME=/home/phablet/.cache/min.pparent/downloads/
exec $initpwd/opt/Min/min $dpioptions $sandboxoptions $gpuoptions
