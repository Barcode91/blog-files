---
title: "$Tmux Notları"
date: 2020-08-31T22:53:43+03:00
draft: false
toc: false
images:
tags: [] 
categories: []
author : "Barcode"
  
---
*Tmux -> Terminal Multiplexer* 

Tmux bir terminal çoklayıcıdır. Bir terminal ekranında birden fazla pencere ve bu pencere içerisinde biden fazla bölme oluşturulabilmektedir. Terminal üzerinde çalışanlar için oldukça bir araçtır.


## Kurulum
```bash
    #Debian, Ubuntu ve Türevleri için Kurulum Komutları
    $ sudo apt-get install tmux

    #Centos Kurulum Komutları
    $ yum -y install tmux
```
## Çalıştırma ve Kullanım
```bash
    #Tmux çalıştırılması
    $tmux
```
Tmux çeşitli tuş kombinasyonları ile kullanılmaktadır. Komutlar prefix key tuşuna basıldıktan sonra girilmektedir.

**Prefix Key => Crtl+B**  Tuşlara aynı anda basılır ve bırakılır daha sonra diğer tuşlara basılır.

Ctrl+B Tuş Kombinasyonundan sonra kullanılan tuşlar;

```tmux
    % pencereleri dikey olarak böler
    " pencereleri yatay olarak böler 
    <Yön Tuşları> pencereler arası gezinti
```

## Pencerelerin Kapatılması

Aktif pencere de __*$ exit*__ komutu yazılarak yada __*Ctrl+D*__ tuş kombinasyonu kullanılarak bölme kapatılır.