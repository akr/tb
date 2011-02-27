#!/bin/sh

# Ubuntu libjakarta-poi-java package installs /usr/share/java/jakarta-poi.jar.

d="`dirname $0`"
d="`cd $d; pwd`"
d="`dirname $d`"

exec jruby -Ku \
-I"$d/lib" \
-I/usr/share/java \
"$d/sample/poi-xls2csv.rb" \
"$@"
