#!/bin/bash
##############################################
#
# Phody
# - Photo Of The Day, primarily designed for GeekTool
#
# Author: Hoffman Tsui
# Version: 2015-03-29.0
#
##############################################

# Configuration
fname_tag=picOfDay              # name of the photo
d_potd=~/Pictures/PhotoOfTheDay # folder that save the photo
dfmt=jpg                        # desired image type of the photo

# DO NOT CHANGE the configuration below
date=`date -j "+%Y%m%d"`
datetime=`date -j "+%D %T"`
uid_tag=_${date}
f_archive=${d_potd}/${fname_tag}${uid_tag}
f_potd=${d_potd}/${fname_tag}
exec_path=`echo "$0" | sed 's/[^/]\{1,\}$//'`
f_html=.potd.tmp
f_pic=.pic.tmp
f_html=${exec_path}${f_html}
f_pic=${exec_path}${f_pic}
f_book=${d_potd}/${fname_tag}_Book.txt
cd $exec_path

# Input the image source
#src=$1         # TODO: extend to include other sources
src=ng

# Decide the source URL and parsing factors
case "$src" in
ng) url='http://photography.nationalgeographic.com/photography/photo-of-the-day/'
    helm=img
    dom=primary_photo
    n=5
    ;;
*)  ;;
esac

# Download the page and Prase the URL and Description of the image
curl -s -i -X GET $url | grep $dom -A $n | grep $helm > $f_html
purl=http:`cat $f_html | sed 's/.*src="\([^"]\{1,\}\).*/\1/' `
pdes=`cat $f_html | sed 's/.*alt="\([^"]\{1,\}\).*/\1/'`
pfmt=`echo $purl | sed 's/.*\.\(.*\)$/\1/'`

# Download image, replace existing
curl -s -X GET $purl -o $f_pic

# Archive image, with single archive backup
new=${f_potd}.${pfmt}
arv=${f_archive}.${pfmt}

if [ -f $new ]; then
    if [ ! -f $arv ]; then
        mv -f $new $arv
    else
        asm=`cksum $arv | awk '{print $1}'`
        nsm=`cksum $new | awk '{print $1}'`
        if [[ $asm != $nsm ]]; then
            mv $arv ${arv}.bkp
            mv $new $arv
        fi
    fi
fi
cp $f_pic $new

# Log the photo description
if [[ ! -f $f_book || "" == `grep "$pdes" $f_book` ]]; then
    echo "$date $pdes" >> $f_book
fi

# Convert image format if necessary
if [[ "$pfmt" != "$dfmt" ]]; then
    case $pfmt in
    gif) convert -strip $new ${f_potd}.${dfmt}
        ;;
    *) convert $new ${f_potd}.${dfmt}
        ;;
    esac
fi

# (Disabled clean up to avoid disk fragmentation)
# Clean up
#rm $f_html
#rm $f_pic

# Print a line of update time (for GeekTool purpose ONLY)
echo "Last updated: $datetime.
$pdes"
