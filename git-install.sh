sudo apt-get install dh-autoreconf libcurl4-gnutls-dev libexpat1-dev \
  gettext libz-dev libssl-dev

sudo apt-get install asciidoc xmlto docbook2x

sudo apt-get install install-info

tar -zxf git-2.31.0.tar.gz -C /usr/local/src/
cd !$
cd git-2.31.0

make configure

./configure --prefix=/usr

make all doc info

sudo make install install-doc install-html install-info


