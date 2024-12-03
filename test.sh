#!/bin/bash

# test json decoder

echo "Extracting tests/test1.json to testoutput.txt. This will just extract the text only"
elm-cli run --debug Extract.elm > testoutput.txt