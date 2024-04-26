#!/bin/bash

disk2=$(lsblk -o NAME,TYPE | grep disk | awk 'NR==2 {print $1}')
disk2_size=$(lsblk -bno SIZE /dev/"$disk2")
disk2_size_gb=$(echo "scale=2; $disk2_size / 1024 / 1024 / 1024" | bc)

disk3=$(lsblk -o NAME,TYPE | grep disk | awk 'NR==3 {print $1}')
disk3_size=$(lsblk -bno SIZE /dev/"$disk3")
disk3_size_gb=$(echo "scale=2; $disk3_size / 1024 / 1024 / 1024" | bc)

disk4=$(lsblk -o NAME,TYPE | grep disk | awk 'NR==4 {print $1}')
disk4_size=$(lsblk -bno SIZE /dev/"$disk4")
disk4_size_gb=$(echo "scale=2; $disk4_size / 1024 / 1024 / 1024" | bc)

echo "Ikinci disk: /dev/$disk2 - $disk2_size_gb GB"
echo "Ucuncu disk: /dev/$disk3 - $disk3_size_gb GB"
echo "Dorduncu disk: /dev/$disk4 - $disk4_size_gb GB"

read -p "Yukaridaki disk bilgileri dogru mu? (yes/no): " confirmation

if [ "$confirmation" == "yes" ]; then
    echo "Disk bilgileri dogru."

    mkfs.ext4 /dev/"$disk2"
    echo "Ikinci disk basariyla biçimlendirildi (ext4)."

    mkfs.ext4 /dev/"$disk3"
    echo "Ucuncu disk basariyla biçimlendirildi (ext4)."

    pvcreate /dev/"$disk4"
    echo "Dorduncu disk fiziksel birim olarak tanitildi (pvcreate)."


    vgcreate vgcb /dev/"$disk4"
    echo "Dorduncu disk birlesik birim olarak olusturuldu (vgcreate)."

    
    vgdisplay

    
    vgdisplay_output=$(vgdisplay)    
    adjusted_size=$(echo "$disk4_size_gb - 0.2" | bc)
    lvcreate -n lvcb -L${adjusted_size}GB vgcb

    
    lvscan

    mkfs.ext4 /dev/vgcb/lvcb
    echo "Birlesik birim lvcb basariyla biçimlendirildi (ext4)."

    # lsblk komutu
    lsblk


    echo "/dev/mapper/vgcb-lvcb /var/cb/data              ext4    defaults        0 0" >> /etc/fstab
    echo "/dev/$disk3 /tmp                               ext4    defaults        0 0" >> /etc/fstab
    echo "/dev/$disk2 /var/log/cb                        ext4    defaults        0 0" >> /etc/fstab

    echo "fstab güncellendi."
    lsblk
    read -p "Sistem yeniden baslatilsin mi? (yes/no): " restart_confirmation

if [ "$restart_confirmation" == "yes" ]; then
    echo "Sistem yeniden baslatiliyor..."
    reboot
elif [ "$restart_confirmation" == "no" ]; then
    echo "Sistem yeniden baslatilmayacak."
    exit 0
else
    echo "Geçersiz yanit."
    exit 1
fi


elif [ "$confirmation" == "no" ]; then
    echo "Disk bilgileri yanlis."
else
    echo "Geçersiz yanit."
fi
