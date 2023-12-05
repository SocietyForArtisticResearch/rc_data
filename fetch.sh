#!/bin/sh

rm internal_research.json
wget keywords.sarconference2016.net/internal_research.json
python3 screenshot.py
