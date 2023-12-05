#!/bin/sh

cd /home/casper/devel/rc_data
rm internal_research.json
wget keywords.sarconference2016.net/internal_research.json
npx elm-cli run src/Main.elm
cp enriched.json /var/www/html/enriched.json
