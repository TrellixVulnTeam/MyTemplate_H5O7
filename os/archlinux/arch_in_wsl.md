# 1. Install `Arch Linux`

## 1. Use `ArchWSL`

See https://github.com/yuk7/ArchWSL

## 2. Use `wsldl` (might not work properly)

0.  Download `Launcher.exe` from https://github.com/yuk7/wsldl

0.  Rename `Launcher.exe` to any distro name you want, e.g. `Arch.exe`

0.  Download latest bootstrap iso `archlinux-bootstrap-????.??.??-x86_64.tar.gz` from https://archlinux.org/download/

0.  Rename `archlinux-bootstrap-????.??.??-x86_64.tar.gz` to `rootfs.tar.gz`

0.  Run `Arch.exe` (formerly `Launcher.exe`)

## 3 Use `LxRunOffline`

0.  Download and unzip `LxRunOffline.exe` from https://github.com/DDoSolitary/LxRunOffline

0.  Download latest bootstrap iso `archlinux-bootstrap-????.??.??-x86_64.tar.gz` from https://archlinux.org/download/

0.  Run `LxRunOffline.exe i -r root.x86_64 -n <any_distro_name_you_want> -d <install_location> -f <bootstrap_file>`

# 2. Configure `Arch Linux`

0.  WSL2 Linux Kernel update: https://www.catalog.update.microsoft.com/Search.aspx?q=wsl

0.  Set as WSL2 (windows): `wsl --set-version <distro_name> 2`

0.  Launch `Arch Linux`

0.  Fix `/usr/lib/wsl/lib/libcuda.so.1 is not a symbolic link` (the terminal under Windows needs admin permission)
    ```
    cd /mnt/c/Windows/System32/lxss/lib/
    mv libcuda.so.1 ~libcuda.so.1
    mv libcuda.so   ~libcuda.so
    ln -s libcuda.so.1.1 libcuda.so.1
    ln -s libcuda.so.1.1 libcuda.so
    ```
    
0.  Shutdown WSL and restart.

0.  Edit `/etc/pacman.conf`, uncomment the line `Color` and `ParallelDownloads` under `# Misc options` and save. E.g.:
    ```
    sed -i s/^#Color/Color/ /etc/pacman.conf
    sed -i s/^#VerbosePkgLists/VerbosePkgLists/ /etc/pacman.conf
    sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 16\nILoveCandy/' /etc/pacman.conf
    ```

0.  Edit `/etc/locale.gen`, uncomment the line of locale you want to use, save it, and run `locale-gen`. E.g.:
    ```
    sed -i s/^#en_US.UTF-8/en_US.UTF-8/ /etc/locale.gen
    locale-gen
    ```

0.  *Note: Only do this under amd64!* Backup `/etc/pacman.d/mirrorlist`:
    ```
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist~
    awk '/^## Worldwide$/{f=1; next}f==0{next}/^$/{exit}{print substr($0, 2);}' /etc/pacman.d/mirrorlist~ \
      >>/etc/pacman.d/mirrorlist
    awk '/^## United States$/{f=1; next}f==0{next}/^$/{exit}{print substr($0, 2);}' /etc/pacman.d/mirrorlist~ \
      >>/etc/pacman.d/mirrorlist
    ```

    ```
    pacman-key --init
    
    # KEYRING=`mktemp` && curl -L https://github.com/archlinuxarm/archlinuxarm-keyring/raw/master/archlinuxarm.gpg -o $KEYRING && pacman-key --add $KEYRING && pacman-key --lsign-key builder@archlinuxarm.org

    pacman -Sy archlinux-keyring
    # pacman -Sy archlinuxarm-keyring

    pacman-key --populate
    # pacman-key --populate archlinuxarm

    pacman -Syu
    gpgconf --kill all
    ```

    Update mirrors with [`reflector`](https://wiki.archlinux.org/title/Reflector), and then rank mirrors with [`rankmirrors`](https://wiki.archlinux.org/title/Mirrors#List_by_speed), by
    ```
    pacman -S reflector
    TMP=`mktemp`
    reflector --sort score -p http,https -c "United States" --save "$TMP" --verbose --connection-timeout 1 --download-timeout 1

    pacman -S pacman-contrib
    rankmirrors -v $TMP | tee /etc/pacman.d/mirrorlist
    ```

0.  *Optional:* Set password for `root` user: `passwd`

0.  *Optional:* Install `nano`:
    ```
    pacman -S nano nano-syntax-highlighting
    printf '\n\n\n## Builtin nanorc\n'   >>/etc/nanorc
    find /usr/share/nano/                     -iname "*.nanorc" -exec echo include {} \; >>/etc/nanorc
    printf '\n\n\n## 3rd party nanorc\n' >>/etc/nanorc
    find /usr/share/nano-syntax-highlighting/ -iname "*.nanorc" -exec echo include {} \; >>/etc/nanorc
    ```

0.  *Optional:* Install `dnscrypt-proxy` to use `DNS over TLS/HTTPS/QUIC/...`:
    ```
    pacman -S dnscrypt-proxy
    echo 'net.core.rmem_max=2500000' >>/etc/sysctl.conf && sysctl -p  # For non-BSD systems    
    sed -i "s/^# server_names =.*/server_names = ['cloudflare','google','yandex','adguard-dns-doh','alidns-doh','dnspod-doh']/" /etc/dnscrypt-proxy/dnscrypt-proxy.toml
    sed -i 's/^# http3 =.*/http3 = true/' /etc/dnscrypt-proxy/dnscrypt-proxy.toml
    if [[ "`uname -a`" = *'microsoft'* ]]; then  # Only required for WSL
        printf '[network]\ngenerateResolvConf = false' >/etc/wsl.conf
        printf 'nameserver 127.0.0.1\n#nameserver 1.1.1.1\n#nameserver 8.8.8.8' >/etc/resolv.conf
        chattr +i /etc/resolv.conf
    fi

    ## Enable and start the service
    systemctl enable --now dnscrypt-proxy.service
    journalctl -u dnscrypt-proxy.service -f  # Check logs and resolve any warnings/errors
    
    ## Or test it with
    dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml
    ```

0. Enable `systemd` for WSL:
    1.  `wsl --update` running 0.67.6+
    2.  `printf "[boot]\nsystemd=true\n" >> /etc/wsl.conf`

0.  Get `sudo`:
    1.  `pacman -S sudo`
    2.  Edit `/etc/sudoers`, uncomment the `# %sudo ALL=(ALL) ALL` and save:
        ```
        sed -i "s/^# %sudo$(printf '\t')ALL/%sudo$(printf '\t')ALL/" /etc/sudoers
        ```
        or uncomment below to allow any user to run sudo if they know the password:
        ```
        # Defaults targetpw  # Ask for the password of the target user
        # ALL ALL=(ALL:ALL) ALL  # WARNING: only use this together with 'Defaults targetpw'
        ```
    
0.  Setup performance optimizations
    -   Filesystem
        ```
        echo 'ALL ALL=(ALL) NOPASSWD: /etc/mount_root_optim.sh' >/etc/sudoers.d/mount_root_optim
        printf '#!/bin/sh\nmount -o remount,lazytime,noatime /' >/etc/mount_root_optim.sh
        printf 'mount -o remount,commit=60,barrier=0 /'        >>/etc/mount_root_optim.sh  # Only for Ext4
        //                                 └ Turn this off only when using battery-backed cache
        chmod +x /etc/mount_root_optim.sh
        echo 'sudo /etc/mount_root_optim.sh' >/etc/profile.d/mount_root_optim.sh

        ROOT_DEVICE=$(findmnt -n -o SOURCE /||df /|head -2|tail -1|cut -d ' ' -f1)
        tune2fs -O "^has_journal"         $ROOT_DEVICE  # Only for Ext4
        tune2fs -o journal_data_writeback $ROOT_DEVICE  # Only for Ext4
        tune2fs -o discard                $ROOT_DEVICE;mount -o remount,discard /  # Only for SSD
        ```
    -   Kernel
        Append the following to `%userprofile%/.wslconfig` in Windows if using WSL:
        ```
        [wsl2]
        kernelCommandLine = "noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off"
        ```
    -   `makepkg`
        ```
        cp /etc/makepkg.conf /etc/makepkg.conf~
        
        sed -i 's/-march=[^ ]*/-march=native/' /etc/makepkg.conf
        sed -i 's/-mtune=[^ ]*//'              /etc/makepkg.conf
        sed -i 's/-O2/-Ofast/'                 /etc/makepkg.conf
        sed -i 's/-D_FORTIFY_SOURCE=2//'       /etc/makepkg.conf
        sed -i 's/-Wp, //'                     /etc/makepkg.conf
        sed -i 's/-fstack-clash-protection//'  /etc/makepkg.conf
        sed -i 's/-fcf-protection//'           /etc/makepkg.conf
        sed -i 's/-D_GLIBCXX_ASSERTIONS//'     /etc/makepkg.conf
        sed -i 's/,-z,relro//'                 /etc/makepkg.conf
        sed -i 's/,-z,now//'                   /etc/makepkg.conf
        
        sed -i 's/DEBUG_CFLAGS="-g"/DEBUG_CFLAGS="-g -D_FORTIFY_SOURCE=2 -fstack-clash-protection -fcf-protection -D_GLIBCXX_ASSERTIONS"/' /etc/makepkg.conf

        sed -i 's/#RUSTFLAGS.*/RUSTFLAGS="-C opt-level=3 -C target-cpu=native"/' /etc/makepkg.conf
        sed -i 's/#DEBUG_RUSTFLAGS/DEBUG_RUSTFLAGS/'                             /etc/makepkg.conf
        
        sed -i 's/#MAKEFLAGS.*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf

        pacman -S ccache && sed -i 's/!ccache/ccache/' /etc/makepkg.conf

        sed -i 's/^OPTIONS=(!strip/OPTIONS=(strip/' /etc/makepkg.conf
        sed -i 's/!lto/lto/' /etc/makepkg.conf
        
        sed -i 's/xz -c -z -/xz -c -z --threads=0 -/'           /etc/makepkg.conf
        sed -i 's/zstd -c -z -q -/zstd -c -z -q --threads=0 -/' /etc/makepkg.conf
        
        sed -i "s/PKGEXT='.pkg.tar.zst'/PKGEXT='.pkg.tar.xz'/" /etc/makepkg.conf
        sed -i "s/SRCEXT='.src.tar.gz'/SRCEXT='.src.tar.xz'/"  /etc/makepkg.conf
        ```

0.  Add new user:
    1.  Add:
        1.  admin user: `groupadd sudo; useradd -G sudo -m <username>`
        2.  normal user: `useradd -m <username>`

    2.  Set password: `passwd <username>`

    3.  Set default login user: `printf "\n[user]\ndefault=$whoami\n" >> /etc/wsl.conf`

0.  Allow non-root user to `ping`
    ```
    echo 'net.ipv4.ping_group_range=0 2147483647' >>/etc/sysctl.conf && sysctl -p
    ```

0.  Login with user other than `root` and install `yay` (or `paru`):
    ```
    cd `mktemp -d`
    curl -JOL https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay-bin
    sudo pacman -S binutils
    makepkg -si
    ```
