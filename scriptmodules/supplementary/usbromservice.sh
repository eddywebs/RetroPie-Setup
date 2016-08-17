#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="usbromservice"
rp_module_desc="USB ROM Service"
rp_module_section="config"

function depends_usbromservice() {
    local depends=(rsync ntfs-3g)
    if [[ "$__raspbian_ver" -gt 7 ]]; then
        if ! hasPackage usbmount 0.0.24; then
            depends+=(debhelper devscripts pmount lockfile-progs)
            getDepends "${depends[@]}"
            if [[ "$md_mode" == "install" ]]; then
                rp_callModule usbromservice sources
                rp_callModule usbromservice build
                rp_callModule usbromservice install
            fi
        fi
    else
        depends+=(usbmount)
        getDepends "${depends[@]}"
    fi
}

function sources_usbromservice() {
    gitPullOrClone "$md_build" https://github.com/RetroPie/usbmount.git systemd
}

function build_usbromservice() {
    dpkg-buildpackage
}

function install_usbromservice() {
    dpkg -i ../*_all.deb
}

function enable_usbromservice() {
    cp -v "$scriptdir/scriptmodules/$md_type/$md_id/01_retropie_copyroms" /etc/usbmount/mount.d/
    sed -i -e "s/USERTOBECHOSEN/$user/g" /etc/usbmount/mount.d/01_retropie_copyroms
    chmod +x /etc/usbmount/mount.d/01_retropie_copyroms
    iniConfig "=" '"' /etc/usbmount/usbmount.conf
    iniGet "FILESYSTEMS"
    if [[ "$ini_value" != *ntfs* ]]; then
        iniSet "FILESYSTEMS" "$ini_value ntfs"
    fi
    iniGet "MOUNTOPTIONS"
    local uid=$(id -u $user)
    local gid=$(id -g $user)
    if [[ ! "$ini_value" =~ uid|gid ]]; then
        iniSet "MOUNTOPTIONS" "$ini_value,uid=$uid,gid=$gid"
    fi
    rm -f /etc/usbmount/mount.d/01_retropie_directusb #delete the directusb script
}

function enable_directusbromservice() {
    cp -v "$scriptdir/scriptmodules/supplementary/usbromservice/01_retropie_directusb" /etc/usbmount/mount.d/
    sed -i -e "s/USERTOBECHOSEN/$user/g" /etc/usbmount/mount.d/01_retropie_directusb
    chmod +x /etc/usbmount/mount.d/01_retropie_directusb
    cp -v "$scriptdir/scriptmodules/supplementary/usbromservice/01_umount_usb" /etc/usbmount/umount.d/
    sed -i -e "s/USERTOBECHOSEN/$user/g" /etc/usbmount/umount.d/01_umount_usb
    chmod +x /etc/usbmount/umount.d/01_umount_usb
    #add symlink cleanup service on boot-bug where reboot and usb disconnection caused sysm link files and folder from direct read service to remain
    cp -v "$scriptdir/scriptmodules/supplementary/usbromservice/01_umount_usb" /etc/profile.d/
    sed -i -e "s/USERTOBECHOSEN/$user/g" /etc/profile.d/01_umount_usb
    chmod +x /etc/profile.d/02_umount_usb

    rm -f /etc/usbmount/mount.d/01_retropie_copyroms #delete the traditional copyroms script
}

function disable_usbromservice() {
    rm -f /etc/usbmount/mount.d/01_retropie_copyroms
    rm -f /etc/usbmount/mount.d/01_retropie_directusb
    rm -f /etc/usbmount/umount.d/01_umount_usb
    rm -f /etc/profile.d/02_umount_usb
}

function remove_usbromservice() {
    disable_usbromservice
    apt-get remove -y usbmount
}

function gui_usbromservice() {
    while true; do
        cmd=(dialog --backtitle "$__backtitle" --menu "Choose from an option below." 22 86 16)
        options=(
            1 "Enable USB ROM Service"
            2 "Enable direct read from USB"
            3 "Disable USB ROM Service"
            3 "Remove usbmount daemon"
        )
        choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choices" ]]; then
            case $choices in
                1)
                    rp_callModule "$md_id" depends
                    rp_callModule "$md_id" enable
                    printMsgs "dialog" "Enabled $md_desc"
                    ;;
                2)
                    enable_directusbromservice
                    printMsgs "dialog" "Enabled direct $md_desc"
                    ;;
                3)
                    rp_callModule "$md_id" disable
                    printMsgs "dialog" "Disabled $md_desc"
                    ;;    
                4)
                    rp_callModule "$md_id" remove
                    printMsgs "dialog" "Removed $md_desc"
                    ;;
            esac
        else
            break
        fi
    done
}
