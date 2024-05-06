#!/bin/bash

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

pyenv which python
cd /home/casper/devel/rc_data

echo "fetch a fresh internal_research.json"
rm internal_research.json
wget keywords.sarconference2016.net/internal_research.json

echo "run screenshots.py to update new screenshots"
echo "what is the version of python"
python3 --version
python3 screenshot.py

echo "make the index json of the screenshots"
cd screenshots
ocaml structure_extract.ml ./ > screenshots.json
cd ..

echo "make a new enriched json file"
elm-cli run src/Main.elm

echo "copy to live app"
cp enriched.json /var/www/html/rc-prisma/enriched.json
cp enriched.json /var/www/html/enriched.json
