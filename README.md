# ckeditor-markdown

This is a Markdown extension for CKEditor.  This is intended to be a complete
WYSIWYG editor for markdown.

Due to ambiguity, you have to set some options for the markdown generator.

## Ambiguities

### Headlines

There are three ways of specifying headlines:

- leading pound
- embracing pound
- underline

### Lists.

You can specify the order of list characters for different levels of Lists:

- first level: `*`
- second level: `-`
- third level: `+`
- lower levels: '-'

## Development

For development, you need `npm` and `make` to be installed (and some basic unix
tools).

- `make `


### Running tests

Go to `ckeditor-dev` folder and ther run `bender server run`.  With your browser
visit http://localhost:1030.  In search bar you can search for `markdown`.
Click to run the tests.

