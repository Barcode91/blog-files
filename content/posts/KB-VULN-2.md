---
title: "VULN KB VULN:2 Write Up"
date: 2020-09-25T20:01:07+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,sudo,smb,samba,smbclient] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/kb-vuln-2,562/) 'da yer alan KB-VULN: 2 adlı makinanın çözümünden bahsedeceğim. Makina için [KernelBlog](https://kernelblog.org) ekibine teşekkür ederim. Keyifli okumalar..."
cover : images/vulnhub/kb-vuln2/cover.png
  
---
Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/kb-vuln-2,562/) 'da yer alan KB-VULN: 2 adlı makinanın çözümünden bahsedeceğim. Makina için [KernelBlog](https://kernelblog.org) ekibine teşekkür ederim. Keyifli okumalar...

## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth0
```

{{< image src="/images/vulnhub/kb-vuln2/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Ip adresi tespit edildikten sonra nmap ile makinenin açık portları ve portlarda çalışan servisleri tespit edilir.

{{< image src="/images/vulnhub/kb-vuln2/nmap.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Tarayıcı ile istek atıldığında Apache Web server varsayılan sayfası açılmaktadır. Web dizin taraması gerçekleştirilir. 
```terminal
gobuster dir -u http://192.168.56.108/ -w /usr/share/wordlists/dirb/big.txt
```
{{< image src="/images/vulnhub/kb-vuln2/gobuster.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

***/wordpress*** dizinine istek atıdığında anasayfanın düzgün görüntülenmediği tespit edilir. /etc/hosts dosyasına ``` 192.168.56.108  kb.vuln ``` eklenir ve yenilenir. Sayfa kaynak kodları incelenir. Herhangi bir bilgiye rastlanmaz. 

{{< image src="/images/vulnhub/kb-vuln2/webpage.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Daha sonra Wordpress CMS dizininde tarama gerçekleştirilir. Standart wordpress dosyaları dışında ilave bir bilgi görülmemektedir. 
```terminal
gobuster dir -u http://192.168.56.108/wordpress -w /usr/share/wordlists/dirb/big.txt
```
{{< image src="/images/vulnhub/kb-vuln2/gobuster2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Nmap taramasında tespit edilen 445 ve 139 numaralı portlarda çalışan samba uygulaması için (SMB Servisi) için ***smbclient*** adlı yazılım ile enumeration yapılır. 

```terminal
smbclient -L ///192.168.56.108
# -L parametresi ağda paylaşılan dosyları listeler
# Username '', Password '' (Anonim Erişim)
```

{{< image src="/images/vulnhub/kb-vuln2/smb1.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Anonymous adlı klasöre şifresiz erişim sağlanabilmektedir. Ayrıca Linux makinalarda samba servisine ***enum4linux*** aracı ile tarama işlemi gerçekleştirilebilmektedir. Erişime açık olan klasöre bağlantı sağlanır. ls komutu ile dizin listelenir.

```terminal
smbclient \\\\192.168.56.108\\Anonymous
```

{{< image src="/images/vulnhub/kb-vuln2/smb2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Bir yedek dosyasının şifresiz bir şekilde paylaşıma açıldığı görülmektedir. Dosya get komutu ile indirilir ve arşiv dosyası açılır. Dosya içerisinde çalışan wordpress uygulmasına ait dosyalar ve bir adet remember_me.txt dosya yer almaktadır. 

{{< image src="/images/vulnhub/kb-vuln2/pass.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Admin kullanıcısına ait parola bilgisi görülmektedir. Wordpress admin paneline giriş yapılır. Daha sonra shell bağlantısı yapmak için tema dosyalarında düzenleme yapılır. Bu işlem için ***Appearance -> Theme Editor*** sekmeleri tıklanır. Açılan sayfada tema secilir. Sağ sütunda php sayfaları yer almaktadır. Ben genelde 404.php dosyasında değişiklik yapmaktayım. 

{{< image src="/images/vulnhub/kb-vuln2/shell.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

```url
http://kb.vuln/wordpress/wp-content/themes/twentynineteen/404.php
```
Netcat ile 4444 numaralı port dinlenir. Yukarıda yer alan adrese istek atıldığında **www-data** kullanıcısı ile terminal bağlantısı sağlanmış olur. 
```python
python -c 'import pty;pty.spawn("/bin/bash")'
```
Komutu ile interaktif shelle geçilir. Home dizinine gidilerek kullanıcılar listelenir. 

{{< image src="/images/vulnhub/kb-vuln2/home.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**Kbadmin** klasör yetkilerine dikkat edildiğinde tüm kullanıcılar tarafında okuma ve çalıştırma yetkisi verildiği görülmektedir. Dizin içerisine girilir.

{{< image src="/images/vulnhub/kb-vuln2/preflag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

User.txt değeri okunarak ilk flag elde edilir.

{{< image src="/images/vulnhub/kb-vuln2/userflag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 3. Yetki Yükseltme
Kbadmin dizininde yer alan note.txt dosyası okunur. Yetki yükseltilmesi ile ilgili docker kullanılması yönünde bir ipucu olabilir.

{{< image src="/images/vulnhub/kb-vuln2/note.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

İlk olarak wordpress admin panelinde elde edilen parola kbadmin kullanıcısı için denenir.  ``` su kbadmin ``` Başarılı bir şekilde kbadmin kullanıcısı ile oturum açılır. :see_no_evil:  ``` sudo -l ``` komutu ile kullanıcı yetkileri kontrol edilir. 

{{< image src="/images/vulnhub/kb-vuln2/sudo.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Kbadmin kullanıcısına sudo işlemlerinde parola girmek şartıyla sınırsız yetki verildiği görülmektedir. ``` sudo su ``` komutu ile root kullanıcısına geçilir. /root dizinine geçilerek flag değeri okunur.

{{< image src="/images/vulnhub/kb-vuln2/rootflag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

