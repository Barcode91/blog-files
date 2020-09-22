---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: false
toc: true
images:
tags: [Vulnhub,write-up,sudo,cron,ftp] 
categories: [write-up]
author : "Barcode"
Description : "Merhaba, Bu yazımda sizlere []() 'da yer alan  adlı makinanın çözümünden bahsedeceğim. Keyifli okumalar..."
cover : images/
  
---
## 1. Keşif Aşaması

Makina kalıp dosyası siteden indirildikten sonra sanallaştırma yazılımları tarafından import edilir ve çalıştırılır. DHCP servisi tarafından atanan ip adresinin tespit edilmesi için netdiscover aracı ile ağda tarama yapılır.

```bash
netdiscover -i eth1
```

{{< image src="/images/" alt="Hay aksi" position="center" style="border-radius: 10px;" >}}



## 2. Erişim Sağlanması


## 3. Yetki Yükseltme
