# IMPORTANT:

The elm part only works if you have RC_API repo in a parallel folder!

# Purpose

This is a command line tool to merge some JSON metadata together, so we don't have to do that on the client side.

Specifically we match any keywords that can be found in the abstract so we can
render it later as hyperlinks. Also, the screenshots are merged into the
records. The end result is an enriched.json that contains all info in one data
structure.

The script is built using [Elm Posix](https://github.com/albertdahlin/elm-posixhttps://github.com/albertdahlin/elm-posix), which is an NPM package to write CLI tools in elm.
Once it will work you can run it using 

```bash
elm-cli run src/Main.elm
``` 

# Extract.elm

Extract.elm is a tool that you can run as follows:

elm-cli src/Extract.elm

You will first need to download metadata using rc_data.py (and update the file url in Extract.elm). It currently works on the basis of a single exposition, which is concatted together into a single textfile (text.txt).




# screenshots and TOC
- [x] increased image size to 1920 x 1440
- [x] added inferred subpages search in default page (subpages not listed in TOC)
- [x] download path mirrors rc path
- [x] Have a list of expositions identified by id, and include the toc info:
- [x] Screenshot folder structure: exposition_id/page_id/index.png
- [x] "smart" zoom
- [ ] make it smarter
- [x] force download
- [x] wait to load pdf if "weave-text" found
- [ ] ? scroll (maybe not possible in --headless with chrome-driver)

# RC data
- [x] tools: get tool ID, position, size, rotation
- [x] text and simpletext: get tool ID, position, size, rotation + content
- [x] tested "tool-text", "tool-simpletext", "tool-picture", "tool-audio", "tool-video", "tool-shape", "tool-pdf","tool-slideshow",
- [x] works for weave-graphical and weave-block
- [ ] pdf, embed, iframe are untested
- [ ] extend to weave-text, weave-html
- [ ] include external hyperlinks in json
- [ ] detect scrollbars
- [ ] make exectuable with exposition ID
- [ ] transform: rotate(0deg) it's the user defined rotation
- [ ] tool-text and simpletext add field "scrollbar" https://www.researchcatalogue.net/view/1755544/1755583

# RC metadata

- [ ] parse tool properties (style etc..)
- [ ] parse all tools

- [ ] number of tools
- [ ] overlap (%)
- [ ] number of links to external content
- [ ] whitespace
- [ ] surface area of tools
- [ ] biggest tool 
- [ ] aspect ratio
- [ ] density
- [ ] regularity
- [ ] tool types
- [ ] number of rotated tools
- [ ] number of shapes 
- [ ] customized style settings (background, padding etc..)

# Parced exposition



## TODO's

[x] Are default positions correctly included in internal_research.json? (casper: yes)




# second step, include tool info:

content = {
    type_ : string
    , url / string / complex 
}

[
    {
        id : exposition_id (int)
        ,toc : [ { page_id (int) , page_title, url (string), screenshot (string)}]
        ,tools : [ tool_id (int) , tool_type (string), content  ]
    }
]

