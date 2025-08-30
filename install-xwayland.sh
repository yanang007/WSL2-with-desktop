#!/bin/bash

# Reference: https://gist.github.com/tdcosta100/e28636c216515ca88d1f2e7a2e188912

SCALE=1
WIDTH=2560
HEIGHT=1600
REFRESH_RATE=240

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "===== STARTING SYSTEM CONFIGURATION ====="

# Update system packages
echo "[STEP 1/8] Updating system packages..."
apt update && apt -y upgrade
echo "[COMPLETE] System packages updated"

# Install required components
echo "[STEP 2/8] Installing desktop components..."
apt install -y ubuntu-desktop xwayland
echo "[COMPLETE] Desktop components installed"

# Create WSLG fix service
echo "[STEP 3/8] Configuring WSLG fix service..."
cat > /etc/systemd/system/wslg-fix.service << 'EOF'
[Service]
Type=oneshot
ExecStart=-/usr/bin/umount /tmp/.X11-unix
ExecStart=/usr/bin/rm -rf /tmp/.X11-unix
ExecStart=/usr/bin/mkdir /tmp/.X11-unix
ExecStart=/usr/bin/chmod 1777 /tmp/.X11-unix
ExecStart=/usr/bin/ln -s /mnt/wslg/.X11-unix/X0 /tmp/.X11-unix/X0
ExecStart=/usr/bin/chmod 0777 /mnt/wslg/runtime-dir
ExecStart=/usr/bin/chmod 0666 /mnt/wslg/runtime-dir/wayland-0.lock

[Install]
WantedBy=multi-user.target
EOF
echo "[COMPLETE] Service file created"

# Configure runtime directory service
echo "[STEP 4/8] Modifying user runtime service..."
mkdir -p /etc/systemd/system/user-runtime-dir@.service.d
cat > /etc/systemd/system/user-runtime-dir@.service.d/override.conf << 'EOF'
[Service]
ExecStartPost=-/usr/bin/rm -f /run/user/%i/wayland-0 /run/user/%i/wayland-0.lock
EOF
echo "[COMPLETE] Runtime service modified"

# Reload systemd configuration
echo "[STEP 5/8] Reloading systemd daemon..."
systemctl daemon-reload
echo "[COMPLETE] Daemon reloaded"

# Enable and start services
echo "[STEP 6/8] Starting WSLG services..."
systemctl enable wslg-fix.service
systemctl start wslg-fix.service
systemctl restart user-runtime-dir@$(id -u).service
systemctl set-default multi-user.target
echo "[COMPLETE] Services activated"

# Configure Xorg replacement
echo "[STEP 7/8] Configuring Xorg replacement..."
if [ -f "/usr/bin/Xorg" ]; then
    mv /usr/bin/Xorg /usr/bin/Xorg.original
    echo "Original Xorg backed up"
else
    echo "No original Xorg found, skipping backing up"
fi

cat > /usr/bin/Xorg.Xwayland << EOF
#!/bin/bash
for arg do
  shift
  case \$arg in
    # Xwayland doesn't support vtxx argument. So we convert to ttyxx instead
    vt*)
      set -- "\$@" "\${arg//vt/tty}"
      ;;
    # -keeptty is not supported at all by Xwayland
    -keeptty)
      ;;
    # -novtswitch is not supported at all by Xwayland
    -novtswitch)
      ;;
    # other arguments are kept intact
    *)
      set -- "\$@" "\$arg"
      ;;
  esac
done

# Check if the runtime dir is present, and create it if not
if [ ! -d \$HOME/runtime-dir ]
then
 mkdir \$HOME/runtime-dir
 ln -s /mnt/wslg/runtime-dir/wayland-0 /mnt/wslg/runtime-dir/wayland-0.lock \$HOME/runtime-dir/
fi

# Point the XDG_RUNTIME_DIR variable to \$HOME/runtime-dir
export XDG_RUNTIME_DIR=\$HOME/runtime-dir

# Find an available display number
for displayNumber in \$(seq 1 100)
do
  [ ! -e /tmp/.X11-unix/X\$displayNumber ] && break
done

# Here you can change or add options to fit your needs
command=("/usr/bin/Xwayland" ":\${displayNumber}" "-geometry" "${WIDTH}x${HEIGHT}" "-fullscreen" "\$@")

systemd-cat -t /usr/bin/Xorg echo "Starting Xwayland:" "\${command[@]}"

exec "\${command[@]}"
EOF

chmod 0755 /usr/bin/Xorg.Xwayland
ln -sf Xorg.Xwayland /usr/bin/Xorg
echo "[COMPLETE] Xorg replacement configured"

# Create display configuration
echo "[STEP 8/8] Creating display configuration..."
mkdir -p ~/.config
cat > ~/.config/monitors.xml << EOF
<monitors version="2">
  <configuration>
    <logicalmonitor>
      <x>0</x>
      <y>0</y>
      <scale>$SCALE</scale>
      <primary>yes</primary>
      <monitor>
        <monitorspec>
          <connector>XWAYLAND0</connector>
          <vendor>unknown</vendor>
          <product>unknown</product>
          <serial>unknown</serial>
        </monitorspec>
        <mode>
          <width>$WIDTH</width>
          <height>$HEIGHT</height>
          <rate>$REFRESH_RATE</rate>
        </mode>
      </monitor>
    </logicalmonitor>
  </configuration>
</monitors>
EOF

mkdir -p /var/lib/gdm3/.config
cp ~/.config/monitors.xml /var/lib/gdm3/.config/
chown -R gdm:gdm /var/lib/gdm3/.config/
echo "[COMPLETE] Display configuration applied"
echo "Resolution: ${WIDTH}x${HEIGHT} @ ${REFRESH_RATE}Hz"

echo "===== SYSTEM CONFIGURATION COMPLETED SUCCESSFULLY ====="
echo "Run `sudo systemctl start graphical.target` to start"
