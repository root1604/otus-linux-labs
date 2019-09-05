1. Попасть в систему без пароля несколькими способами
2. Установить систему с LVM, после чего переименовать VG
3. Добавить модуль в initrd

---------------------------------------------------------------------------------------------------------
1. Попасть в систему без пароля несколькими способами
---------------------------------------------------------------------------------------------------------
В меню выбора ядра для загрузки нажать "e". Попадаем в окно где мы можем изменить параметры загрузки:

Способ 1.
В конце строки начинающейся с linux16 добавляем init=/bin/sh и нажимаем сtrl-x для загрузки в систему
mount -o remount,rw /
passwd root
touch /.autorelabel
exec /sbin/init

Способ 2.
В конце строки начинающейся с linux16 добавляем rd.break и нажимаем сtrl-x для загрузки в систему 
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
CTRL-D, CTRL-D

Способ 3.
В конце строки начинающейся с linux16 заменяем ro на rw, добавляем init=/sysroot/bin/sh и нажимаем сtrl-x для загрузки в систему
chroot /sysroot
passwd root
touch /.autorelabel
init 6
----------------------------------------------------------------------------------------------------------
2. Установить систему с LVM, после чего переименовать VG
----------------------------------------------------------------------------------------------------------
vgs
VG #PV #LV #SN Attr VSize VFree
VolGroup00 1 2 0 wz--n- <38.97g 0
vgrename VolGroup00 OtusRoot
Редактируем файлы 
/etc/fstab
/etc/default/grub
/boot/grub2/grub.cfg
меняем VolGroup00 на OtusRoot
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
reboot
vgs
VG       #PV #LV #SN Attr   VSize   VFree
 OtusRoot   1   2   0 wz--n- <38.97g    0 

----------------------------------------------------------------------------------------------------------
3. Добавить модуль в initrd
----------------------------------------------------------------------------------------------------------
mkdir /usr/lib/dracut/modules.d/01test

скрипт, который устанавливает модуль и вызывает скрипт test.sh 
/usr/lib/dracut/modules.d/01test/module-setup.sh 
================================================
#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh"
}
===============================================

сам вызываемый скрипт
/usr/lib/dracut/modules.d/01test/test.sh
===============================================
#!/bin/bash

exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'
Hello! You are in dracut module!
 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo " continuing...."
===============================================

mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
lsinitrd -m /boot/initramfs-$(uname -r).img | grep test

В файле /boot/grub2/grub.cfg из строки, начинающейся с linux16, убираем опции rghb quiet
reboot

В результате при загрузке будет выполнен скрипт test.sh и будет нарисован пингвин



