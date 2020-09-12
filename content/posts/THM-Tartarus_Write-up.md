---
title: "THM Tartarus Write Up"
date: 2020-09-12T20:53:26+03:00
draft: false
toc: false
images:
tags: [Tryhackme,write-up,gobuster,nmap,sudo,crontab,burpsuite] 
categories: [Write-up]
author : "Barcode"
  
---
{{< image src="/images/thm/tartarus/Screenshot_2020-08-28_13-45-54.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}


{{< text >}}
Merhaba, Siber güvenliğe yeni başlayanların ofansif yeteneklerini geliştirebileceği TryHackMe platformunda yer alan, başlangıç seviyesi olan Tartarus adlı makinanın çözümünden bahsedeğim. Hatalı yada ilave açıklama gerektiren yerler için yorum bırakabilirsiniz. Keyifli okumalar...
{{< /text >}}

## 1. Keşif Aşaması

Nmap ile makinenin açık portlar ve portlarda çalışan servisler tespit edilir.

```bash
sudo nmap -sV -sC 10.10.236.165 
```


{{< image src="/images/thm/tartarus/nmap.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Tarayıcı ile web servisine istek atılır. Apache yazılımına ait varsayılan web sayfası açılmaktadır.


{{< image src="/images/thm/tartarus/webpage.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Web dizininde yer alan dosyalar ve klasörlerin tespiti için gobuster kullanılır.

```bash
gobuster dir -u http://10.10.236.165 -w /usr/share/wordlists/dirb/common.txt 
```
{{< image src="/images/thm/tartarus/gobuster.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

{{< text >}}
Gobuster sonucunda robots.txt dosyası dikkat çekmektedir. Robots.txt, arama motoru örümcekleri sitenizin hangi bölümlerini dizine ekleyebileceğini, hangi dizini taraması gerektiğini, hangi arama motoru yazılımının giriş izni olduğunu veya olmadığını söylemeye yarayan basit bir komut dosyasıdır. Dosya içeriği okunur.
{{< /text >}}



{{< image src="/images/thm/tartarus/robots.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

{{< text >}}
Arama motorları tarafından indexlenmesi engellenen <i>/admin-dir</i> dizine giriş yapılır. Dizinde muhtemel kullanıcı adı ve parola listeleri yer almaktadır. Listeler indirilir.  Ftp servisinde anonim olarak erişime açık olan test.txt dosyası incelenir.
{{< /text >}}
{{< image src="/images/thm/tartarus/cat.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

ftp dizininde dolaşılarak araştırmaya devam edilir. **{...}** dizini dikkat çekmektedir. Dizin içerisindeki __*yougotgoodeyes.txt*__ isimli dosya indirilir ve içeriği okunur. 


{{< image src="/images/thm/tartarus/ftpd.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

İçerisinde bir dizin adı yer almaktadır. 

{{< image src="/images/thm/tartarus/secretdir.png" alt="Hello Friend" position="left" style="border-radius: 10px;" >}}
{{< text >}}
Tarayıdan giriş yapıldığında bir login ekranı çıkmaktadır. Elde edilen bilgiler ile burpsuite aracı kullanılarak kaba kuvvet saldırısı yapılır. 

iki adet parametre ve iki ayrı liste olduğundan intruder -> Payload Options -> Cluster Bomb seçilerek kaba kuvvet saldırısı için ayarlamalar yapılır. Ayrıntılı bilgi için aşağıdaki linke bakılabilir.
{{< /text >}}
__*https://portswigger.net/support/using-burp-to-brute-force-a-login-page*__


Username ve Password parametleri işaretlenir.


{{< image src="/images/thm/tartarus/burp1.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Username ve Password parametleri için denenecek verilerin olduğu listeler yüklenir.

{{< image src="/images/thm/tartarus/username.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

 
{{< image src="/images/thm/tartarus/passwd.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Saldırı sonucunda kullanıcı adı ve parola bilgisi elde edilir.

{{< image src="/images/thm/tartarus/result.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Elde edilen oturum bilgileri ile giriş yapılır. Dosya yükleme sayfası gelmektedir. Reverse shell almak için bir [php](https://github.com/pentestmonkey/php-reverse-shell) sayfası upload edilir. 

{{< image src="/images/thm/tartarus/upload.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

{{< text >}}
Gobuster aracı ile <i style="color:yellow">/sUp3r-s3cr3t</i>  dizini altında dosyanın upload edildiği yeri bulmak için dizin taraması yapılır. Tarama sonucunda image dizini tespit edilir. Bu dizin içerisinde de yükleninen php dosyası bulunmamaktadır. <i style="color:yellow">/sUp3r-s3cr3t/images</i> dizini altında da tarama yapılır ve uploads dizini tespit edilir. 
{{< /text >}}

{{< image src="/images/thm/tartarus/upload2.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması
{{< text >}}
Localhosttan netcat ile 4444 portu dinlenmeye başlanır. Daha sonra http://10.10.236.156/sUp3r-s3cr3t/images/uploads/reverse.php adresine gidilir ve terminal bağlantısı sağlanır.
{{< /text >}}
{{< image src="/images/thm/tartarus/ncat.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Düşük kullanıcı ile shell alındığından user.txt dosyasını okumak için yetki yükselmek gereklidir.
```sudo -l ``` komutu girilir. 

{{< image src="/images/thm/tartarus/nc2.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

{{< text >}}
<strong> Thirtytwo </strong> adlı kullanıcı için <i> var/www/gbd</i> uygulaması parola gerektirmeden çalıştırılabildiği tespit edilmektedir. Aşağıda yer alan komut ile kullanıcı bağlanır ve gdb istismar edilerek  thirtytwo kullanıcısına giriş yapılır.
{{< /text >}}
```bash
sudo -u thirtytwo /var/www/gdb -nx -ex '!sh' -ex quit
```

{{< image src="/images/thm/tartarus/32.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Python pty modülü kullanılarak interaktif shelle geçilir. 

```python
python -c 'import pty; pty.spawn("/bin/bash")'
```

Home dizininde yer alan diğer kullanıcı dizininde yer alan user.txt dosyası okunur.

{{< image src="/images/thm/tartarus/user.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

## 3. Yetki Yükseltme

Yetki yükseltme aşamasında crontab da zamanlanmış görevlere bakıldığında root yetkisi ile cleanup.py dosyasının her iki dakikada bir çalıştırıldığı görülmektedir. 


{{< image src="/images/thm/tartarus/crontab.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Dosyanın yetkilerine bakıldığında içeriğinin değiştirilebileceği görülmektedir.

{{< image src="/images/thm/tartarus/ls.png" alt="Hello Friend" position="left" style="border-radius: 10px;" >}}

Cleanup.py dosyasının içeriği aşağıdaki gibi değiştirilir.

{{< image src="/images/thm/tartarus/pri.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Netcat ile 5555 numaralı port dinlenir. Zamanlanmış görev çalıştığında root yetkisi ile reverse shell bağlantısı sağlanmış olur.

{{< image src="/images/thm/tartarus/reverse.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Root dizini altında yer alan root.txt dosyası okunurak makina tamamlanır.
{{< image src="/images/thm/tartarus/root.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}



















