(->
  debug = console.log.bind console, "markdown:"

  markedOpts = {
    renderer: new marked.Renderer()
  }

  markedOpts.renderer.heading = (text, level, raw) ->
      return """<h#{level}>#{text}</h#{level}>\n"""

  CKEDITOR.on 'dialogDefinition', (ev) ->
    debug "=> dialogDefinition"
    {name, definition} = ev.data

  decodeEntities = do ->
    # this prevents any overhead from creating the object each time
    element = document.createElement('div')

    (str) ->
      if str && typeof str is 'string'
        # strip script/html tags
        str = str.replace(/<script[^>]*>([\S\s]*?)<\/script>/gmi, '')
        str = str.replace(/<\/?\w(?:[^"'>]|"[^"]*"|'[^']*')*>/gmi, '')
        element.innerHTML = str
        str = element.textContent
        element.textContent = ''

      return str

  wrapped = (text, l)	->
    o = []
    s = text
    len = 0
    last = 0

    tail = text.replace /((?:^|\n)[ \t]+[^\n]+\n|(?:^|\n)[ \t]*```(?:.|\n)*(?:^|\n)[ \t]*```[ \t]*\n)|(\S+)(\s|$)/g, (m, pre, word, space) ->
      len += m.length
      if len > l
        len = m.length
        o[o.length-1] = "\n"
        #o.push "\n"
      if pre
        o.push pre
      else
        o.push word, space

      return ''

    return o.join('') + tail

  initCss = ->
    blockNames = """
      p div blockquote address
      h1 h2 h3 h4 h5 h6
      dl dt dd
      ul ol li
    """.trim().split /\s+/

  handleHeadline =
    textOutput: no

  handleLink = (node) ->
    result = ''
    debugger
    if node.attr.alt
      result += node.attr.alt
    if node.attr.href
      result += "](#{node.attr.href}"
    else if node.attr.src
      result += "](#{node.attr.src}"
    if node.attr.title
      result += ' "' + node.attr.title + '"'
    result += ')'
    result

  html2markdown = {
    h1: ['# ', '\n']
    h2: ['## ', '\n']
    h3: ['### ', '\n']
    h4: ['#### ', '\n']
    h5: ['##### ', '\n']
    h6: ['###### ', '\n']
    pre: {
      indent: "    "
    }
    dl: {}
    dt: ['', "\n"]
    dd: {indented: true}
    div: []
    ul: []
    li: (node) ->
      console.log "li", @getParentNode().tag
      if @getParentNode().tag is 'ul'
        return {tagOpen: "", indent: ["* ", "  "], tagClose: "\n\n"}
      else
        return {tagOpen: "", indent: ["1. ", "   "], tagClose: "\n\n"}
    ol: []
    br: {hasCloser: false, tagOpen: "\n", tagClose: ""}
    hr: {hasCloser: false, tagOpen: "---\n", tagClose: ""}
    quote: {}
    tt: ["`", "`"]
    a: ["[", handleLink]
    img: {hasCloser: false, tagOpen: ((node) -> "!["+handleLink(node)) }
    em: ['_', '_']
    strong: ['*', '*']
    p: ['', '\n\n']
    blockquote: {
      indent: "> "
    }
  }

  for k,v of html2markdown
    if v instanceof Array
      if v.length == 2
        html2markdown[k] = {tagOpen: v[0], tagClose: v[1]}
      else
        html2markdown[k] = {}

    if v.tags instanceof Array
      html2markdown[k].tagOpen = v.tags[0]
      html2markdown[k].tagClose = v.tags[1]

  CKEDITOR.htmlParser.fragment.fromMarkdown = (source) ->
    debug "=> fromMarkdown"
    html = window.marked source, markedOpts
    debug "html1", html
    fragment = CKEDITOR.htmlParser.fragment.fromHtml html
    fragment

  markdownToHtml = (code) ->
    fragment = CKEDITOR.htmlParser.fragment.fromMarkdown(code)
    writer = new CKEDITOR.htmlParser.basicWriter()

    debug "fragment", fragment

    fragment.writeHtml(writer, markdownFilter)
    html = writer.getHtml yes
    debug "html2", html
    html

  # filter for markdown to HTML, used in markdown2html
  m2hFilterRules =
    elements:
      '^': (element) -> null
      '$': (element) ->
        if element.name is 'li'
          if element.children.length == 1
            if element.children[0].name is 'p'
              element.children = element.children[0].children
              return element
        # if element.name is 'p'
        #   if element.parent
        #     if element.parent.name is 'li'
        #       debugger
        #       if element.parent.children.length == 1
        #         return element.children

        if element.name in ['blockquote', 'p']
          return element

  markdownFilter = new CKEDITOR.htmlParser.filter()
  markdownFilter.addRules m2hFilterRules

  debug "done setup markdown to html"


  # filter for HTML to markdown
  h2mFilterRules =
    elements:
      '^': (element) -> null

      '$': (element) ->
        if element.name in ['blockquote', 'p']
          element

      # br: (element) ->
      #   next = {element}
      #   if next && next.name in blockLikeTags
      #     return false
      #   element

  class MarkdownWriter extends CKEDITOR.htmlParser.basicWriter

    constructor: ->
      super()
      #@setRules 'list'
      @_.stack = []

    openTag: (tag) ->
      attr = {}
      output = ''
      @_.stack.push {tag, attr, output}

    _write: (text) ->
      current = @getCurrentNode()
      console.log "current", current
      if current
        current.output += text
      else
        @write text

    text: (text) ->
      # escape text
      text = decodeEntities text
      text = text.replace /^(\d+)\.\s/m, (m, num) -> num + "\\. "

      @_write wrapped(text, 75)

    getCurrentNode: ->
      @_.stack[@_.stack.length-1]

    getParentNode: ->
      if @_.stack.length < 2
        return null
      @_.stack[@_.stack.length-2]

    getSpec: (node) ->
      if node.spec
        return node.spec

      console.log "node-tag", node.tag

      spec = html2markdown[node.tag] || {}

      if spec instanceof Function
        spec = spec.call this, node

      node.spec = spec
      return spec

    openTagClose: (tag) ->
      current = @getCurrentNode()
      spec = @getSpec current

      s = spec.tagOpen || ""
      if s instanceof Function
        s = s.call this, current
      else
        if spec.tagOpenHasVar
          s = varString s, current.attr

      @_write(s)

      if spec.hasCloser is false
        @flush()

    attribute: (name, val) ->
      current = @getCurrentNode()
      current.attr[name] = val

    reset: ->
      super()
      @_.stack = []

    flush: ->
      current = @_.stack.pop()
      data = current.output or ''

      console.log "spec", current.spec

      if 'indent' of current.spec
        indent = current.spec.indent
        first = indent
        if indent is true
          first = indent = "    "
        else if indent instanceof Array
          [first, indent] = indent

        # if 'indent' of current.attr
        #   indent = current.attr.indent
        console.log "data1", data

        data = first + data # wrapped(data, 75)

        console.log "data2", data
        data = data.replace(/\n(?!$)/g, "\n"+indent)

        console.log "data3", data

      @_write data


    closeTag: (tag) ->
      current = @getCurrentNode()
      spec = @getSpec current

      s = spec.tagClose || ""
      if s instanceof Function
        s = s.call(this, current) || ''
      else
        if spec.tagCloseHasVar
          s = varString s, current.attr

      @flush()

      @_write(s)

      if spec.next
        @spec_stack.pop()

  writer = new MarkdownWriter()

  debug "done setup html to markdown"

  CKEDITOR.plugins.add 'markdown', {
    requires: 'entities,richcombo'

    beforeInit: (editor) ->
      debug "=> beforeInit"
      {config} = editor
      editor.dataProcessor.htmlFilter.addRules h2mFilterRules, applyToAll: false

    init: (editor) ->
      debug "=> init"

      {config} = editor

      editor.dataProcessor.writer = writer

      onSetData = (evt) ->
        evt.data.dataValue = markdownToHtml evt.data.dataValue

      if editor.elementMode == CKEDITOR.ELEMENT_MODE_INLINE
        editor.once 'contentDom', ->
          editor.on 'setData', onSetData
      else
        editor.on 'setData', onSetData

    afterInit: (editor) ->
      debug "=> afterInit"
      {config} = editor
  }

  pluginPath = CKEDITOR.plugins.getPath('markdown')

)()
