#!/bin/sh
sed -i \
         -e 's/#171A1F/rgb(0%,0%,0%)/g' \
         -e 's/#DFDFDF/rgb(100%,100%,100%)/g' \
    -e 's/#131519/rgb(50%,0%,0%)/g' \
     -e 's/#404eed/rgb(0%,50%,0%)/g' \
     -e 's/#22262e/rgb(50%,0%,50%)/g' \
     -e 's/#DFDFDF/rgb(0%,0%,50%)/g' \
	"$@"
