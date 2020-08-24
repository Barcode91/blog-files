rm -r site
git submodule add -b master https://github.com/Barcode91/barcode91.github.io.git site
cd site
git add -A 
git commit -m $1 
git push origin master
rm -r site

