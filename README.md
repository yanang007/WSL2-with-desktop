WSL2-with-desktop
-----------------

`WSL2-with-desktop` provides script-version of [tdcosta100/WSL2GUIWSLg-XWayland](https://gist.github.com/tdcosta100/e28636c216515ca88d1f2e7a2e188912).

Prerequisites
-------------
- Windows 11
- [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install)
- Ubuntu 24.04 (Consider [this guide](https://gist.github.com/tdcosta100/385636cbae39fc8cd0937139e87b1c74) for other Ubuntu versions)
- systemd enabled in WSL2 (check `/etc/wsl.conf` for `systemd=true`)

Usage
-----
1. Install Ubuntu 24.04 on WSL2. (This script is tested on Ubuntu 24.04 only.)

2. Download `install-xwayland.sh` from this repository.

> [!NOTE]
> For users from China, consider `install-xwayland-cn.sh` with extra mirror configurations.

3. Run the script with administrator privilege.

    ```bash
    sudo bash install-xwayland.sh
    ```

4. Start graphical desktop environment.

    ```bash
    sudo systemctl start graphical.target
    ```

Customize
---------
Every step is customizable. Edit the script to fit your needs.

### 1. Display Parameters

Edit the variables at the top of the script to customize your display settings:

```bash
SCALE=1              # Display scaling factor (1 = 100%, 1.5 = 150%, etc.)
WIDTH=2560           # Screen width in pixels
HEIGHT=1600          # Screen height in pixels  
REFRESH_RATE=240     # Monitor refresh rate in Hz
```

**Examples:**
- For 4K display: `WIDTH=3840 HEIGHT=2160`
- For 1080p display: `WIDTH=1920 HEIGHT=1080`
- For high DPI displays: `SCALE=1.5` or `SCALE=2`

> [!NOTE]
> For advanced configurations, you can modify the `monitors.xml` file generated in STEP 8.

### 2. Desktop Environment

The script installs `ubuntu-desktop` by default. You can replace it with other desktop environment metapackage.

See [here](https://gist.github.com/tdcosta100/e28636c216515ca88d1f2e7a2e188912#installing-gui) for more options.

```bash
# Replace this line in STEP 2 (for GNOME)
apt install -y ubuntu-desktop xwayland

# With your preferred desktop:
apt install -y kubuntu-desktop xwayland      # KDE
apt install -y ubuntukylin-desktop xwayland  # Kylin
# ...
```

### 3. Xwayland Options

Modify the Xwayland command options in the Xorg replacement script (STEP 7):

```bash
# Find this line and customize as needed:
command=("/usr/bin/Xwayland" ":${displayNumber}" "-geometry" "${WIDTH}x${HEIGHT}" "-fullscreen" "$@")
```

Troubleshooting
---------------
### 1. Black Screen
Try manually start `gnome-session` before starting `graphical.target`:
