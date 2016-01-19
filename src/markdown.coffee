# bender-tags: editor,unit
# bender-ckeditor-plugins: markdown,entities,enterkey

bender.editor = { config: { autoParagraph: false } }

bender.test {
  setUp: ->
    processor = @editor.dataProcessor

    # Remove protected attributes.
    processor.dataFilter.addRules
      attributeNames: [
        [ ( /^data-cke-.*/ ), '' ]
      ]

  assertToHtml: (html, markdown) ->
    ed = this.editor
    processor = ed.dataProcessor;
    # Fire "setData" event manually to not bother editable.
    evtData = { dataValue: markdown };
    ed.fire( 'setData', evtData );
    assert.areSame( html.toLowerCase(), CKEDITOR.tools.convertRgbToHex( bender.tools.fixHtml( processor.toHtml( evtData.dataValue ) ) ), 'markdown->html' )

  assertToMarkdown: ( markdown, html ) ->
    ed = this.editor
    processor = ed.dataProcessor
    assert.areSame( markdown.trim(), processor.toDataFormat( html ), 'html->markdown failed at:' + markdown )

  'test HTML to Markdown': ->
    this.assertToMarkdown( '*foo*', '<strong>foo</strong>' );
}
