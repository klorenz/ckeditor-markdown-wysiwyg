###
bender-tags: editor,unit
bender-ckeditor-plugins: markdownwysiwyg,entities,enterkey
###

bender.editor = { config: { autoParagraph: false } }

tools = null

bender.test {
  setUp: ->
    tools = CKEDITOR.plugins.registered.markdownwysiwyg.tools

  assertWrapped: (source, expected) ->
    r = tools.wrapped(source, 30)
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

  'test generate open and close tags': ->
    {generateOpenTag, generateCloseTag} = tools
    assert.areSame "<foo>\n", generateOpenTag tag: 'foo'
    assert.areSame '<foo x="y">\n', generateOpenTag tag: 'foo', attr: {x: 'y'}
    assert.areSame '</foo>\n', generateCloseTag tag: 'foo', attr: {x: 'y'}

  'test generate HTML': ->
    {generateHtml} = tools
    assert.areSame """
      <table>
        <tr>
          <td>
            foo
          </td>
          <td>
            bar
          </td>
          <td>
            glork
          </td>
        </tr>
      </table>\n
    """, generateHtml {
      tag: 'table', children: [
        { tag: 'tr', children: [
          {tag: 'td', children: [ "foo" ]}
          {tag: 'td', children: [ "bar" ]}
          {tag: 'td', children: [ "glork" ]}
        ]}
      ]
    }

}
