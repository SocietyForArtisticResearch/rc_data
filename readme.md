
# Purpose

This is a command line tool to merge some JSON metadata together, so we don't have to do that on the client side.
Specifically we match any keywords that can be found in the abstract so we can render it later as hyperlinks.
Later, we can also merge all the screenshot paths into this.

The script is built using [Elm Posix](https://github.com/albertdahlin/elm-posixhttps://github.com/albertdahlin/elm-posix), which is an NPM package to write CLI tools in elm.
Once it will work you can run it using 

```bash
elm-cli run src/Main.elm
``` 


# first step

# first step
Have a list of expositions identified by id, and include the toc info:

[
    {
        id : exposition_id (int)
        ,toc : [ { page_id (int) , page_title, url (string), screenshot (string)}]
    }
]

Screenshot folder structure:

exposition_id/page_id/anchor

exposition_id/page_id/default_position.png

## TODO's

Are default positions correctly included in internal_research.json?


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

