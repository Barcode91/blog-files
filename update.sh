#!/bin/bash
if [[ -d site ]]
then
    mv  site ..
fi
git add *
echo "Local repoya dosyalar eklendi"
git commit -m "add post"
echo "commit tamamlandı"
git push origin master
echo "Github'a kaynak dosyalar yüklendi."
mv ../site .
hugo 
cd site
git add *
echo "Local repoya dosyalar eklendi"
git commit -m "add post"
echo "commit tamamlandı" 
git push origin master
echo "Github'a site dosyaları yüklendi."

