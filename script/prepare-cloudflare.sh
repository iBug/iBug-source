#!/bin/bash

wget -qO - https://github.com/iBug/image/archive/master.tar.gz | tar zxf -
mv -f image-master image
rm -f CNAME .nojekyll LICENSE.md README.md
