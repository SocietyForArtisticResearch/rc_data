#!/bin/sh

rm internal_research.json
wget keywords.sarconference2016.net/internal_research.json
elm-cli run src/Main.elm