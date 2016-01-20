###
bender-tags: editor,unit
bender-ckeditor-plugins: markdownwysiwyg,entities,enterkey
###

bender.editor = { config: { autoParagraph: false } }

mdplugin = null

bender.test {
  setUp: ->
    mdplugin = CKEDITOR.plugins.registered.markdownwysiwyg

  assertWrapped: (source, expected) ->
    r = mdplugin.tools.wrapped(source, 30)
    assert.areSame(expected, r)

  'test simple wrapping': -> this.assertWrapped """
      This is a very long line, which has far beyond 75 characters.  It should be wrapped at the correct
      position.
    """, """
      This is a very long line,
      which has far beyond 75
      characters. It should be
      wrapped at the correct
      position.
    """

  'test no wrapping in preformatted blocks': -> this.assertWrapped """
      This is a very long line, which has far beyond 75 characters.  It should be wrapped at the correct position. The line is far far longer.

      ```
        here is also a very long line, but it is a
        preformatted line, so it should not be wrapped.
        more text
      ```
    """, """
      This is a very long line, which has far beyond 75 characters.  It should
      be wrapped at the correct position. The line is far far longer.

      ```
        here is also a very long line, but it is a preformatted line, so it should not be wrapped.
        more text
      ```
    """
}
