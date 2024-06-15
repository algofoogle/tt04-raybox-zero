#/!usr/bin/bash

for f in rbz_basic_frame-???.ppm; do
    echo $f
    convert $f ~/HOST_Documents/ppm/$f.png
done

