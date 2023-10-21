#!/bin/sh



# first make the index of the screenshots
cd screenshots
ocaml structure_extract.ml ./ > screenshots.json
cd ..

# remove stale data and fetch fresh metadata
rm internal_research.json
rm enriched.json
wget keywords.sarconference2016.net/internal_research.json
elm-cli run src/Main.elm
cp enriched.json ../rckeywords/enriched.json
