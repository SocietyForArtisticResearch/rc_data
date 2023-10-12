#!/bin/sh
# first make the index of the screenshots
cd screenshots
ocaml structure_extract.ml ./ > screenshots.json
cd ..
# remove stale data and fetch fresh metadata
rm internal_research.json
wget keywords.sarconference2016.net/internal_research.json
elm-cli run src/Main.elm