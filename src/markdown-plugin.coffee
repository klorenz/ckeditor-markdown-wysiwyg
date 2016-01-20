(->
  debug = console.log.bind console, "markdown:"


  # with marked
  #markedOpts = {
  #   renderer: new marked.Renderer()
  #}
  #
  #markedOpts.renderer.heading = (text, level, raw) ->
  #   return """<h#{level}>#{text}</h#{level}>\n"""
  #
  #htmlFromMarkdown = (source) ->
  #  window.marked source, markedOpts

  # with markdownit
  mdit = markdownit({
      html: true,
      highlight: (code, lang) -> code
  });
  #    .use(markdownitFootnote);

  htmlFromMarkdown = (source) ->
    mdit.render(source.replace(/\t/g, '    '))

  # done

  CKEDITOR.on 'dialogDefinition', (ev) ->
    debug "=> dialogDefinition"
    {name, definition} = ev.data

    if name == 'link'
      definition.removeContents 'target'
      definition.removeContents 'upload'
      definition.removeContents 'advanced'
      tab = definition.getContents 'info'
      tab.remove 'emailSubject'
      tab.remove 'emailBody'
    else if name == 'image'
      definition.removeContents 'advanced'
      tab = definition.getContents 'Link'
      tab.remove 'cmbTarget'
      tab = definition.getContents 'info'
      tab.remove 'txtAlt'
      tab.remove 'basic'

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

  # this is applied to ready done paragraphs.
  #
  wrapped = (text, l)	->
    o = []
    s = text
    len = 0
    last = 0

    console.log "text before: '#{text}'"
    #tail = text.replace /(^([ \t]*)```[\s\S]*?^\2```[ \t]*\n|^[ \t]+[^\n]+\n)|(\S+)(\s|$)/mg, (m, pre, sp, word, space) ->
    tail = text.replace /(\s*)(\S+)(\s|$)/g, (m, prefix, word, space) ->
      console.log(
        "m:", JSON.stringify(m),
        "prefix:", JSON.stringify(prefix),
        "word:", JSON.stringify(word),
        "space:", JSON.stringify(space),
        )
      len += m.length
      if len > l
        len = m.length
        o[o.length-1] = o[o.length-1].replace(/\s*$/, "\n")

      if not prefix
        prefix = ""
      if not space
        space = ""

      o.push prefix+word+space

      # if pre
      #   o.push pre
      # else
      #   o.push word
      #   o.push space if space isnt ''

      return ''

    console.log "tail:", JSON.stringify(tail)

    result = o.join('') # + tail
    console.log "text after: '#{result}'"
    return result

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
    if node.attr.href
      link = node.attr.href
    else if node.attr.src
      link = node.attr.src

    if node.attr.alt and node.attr.alt != link
      result += node.attr.alt

    result += "](#{link}"
    if node.attr.title
      result += ' "' + node.attr.title + '"'
    result += ')'
    result

  writeMarkdownTable = (node) ->
    generateHtml(node)

  generateOpenTag = (node) ->
    s = "<#{node.tag}"
    for a,v of node.attr
      s += " #{a}="+JSON.stringify(v)
    s += ">\n"
    s

  generateCloseTag = (node) ->
    "</#{node.tag}>\n"

  generateHtml = (node) ->
    s = generateOpenTag(node)
    for c in node.children
      s += generateHtml(c)
    s += generateCloseTag(node)
    return s

  html2markdown = {
    h1: ['# ', '\n\n']
    h2: ['## ', '\n\n']
    h3: ['### ', '\n\n']
    h4: ['#### ', '\n\n']
    h5: ['##### ', '\n\n']
    h6: ['###### ', '\n\n']
    pre: (node) ->
      if 'class' not of node.attr
        {indent: "    "}
      else if m = node.attr.class.match /hljs language-(.*)/
        {tagOpen: "```#{m[1]}\n", tagClose: "```\n"}
      else if m = node.attr.class.match /hljs/
        {tagOpen: "```\n", tagClose: "```\n"}
      else
        {indent: "    "}

    table:
      collect: true
      tagClose: (node) ->
        if node.htmlTable
          generateHtml(node)
        else
          writeMarkdownTable(node)

    tbody: {}
    thead: {}
    tfoot: {}
    tr: {}
    col: {}
    row: {}

    td: {tagClose: (node) ->
      if "\n" in node.output
        @getParentNode('table').htmlTable = true
      return {collect: true}
      }

    th: {tagClose: (node) ->
      if "\n" in node.output
        @getParentNode('table').htmlTable = true
      return {collect: true}
      }

    dl: {}
    dt: ['', "\n"]
    dd: {indented: true}
    div: {
      tagOpen: (node) ->
        generateOpenTag(node)+"\n"
      tagClose: (node) ->
        "\n"+generateCloseTag(node)
    }
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
    em: ['*', '*']
    strong: ['**', '**']
    p: {'', tagClose: (node) ->
      node.output = wrapped(node.output, 75)
      return '\n\n'
    }
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
    html = htmlFromMarkdown(source)
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
      children = []

      collect = false
      if @_.stack.length
        current = @getCurrentNode()
        collect = current.collect

      nextSpec = {tag, attr, output, children, collect}
      @_.stack.push nextSpec

      if collect
        current.children.push nextSpec


    _write: (text) ->
      current = @getCurrentNode()
      console.log "current", current
      if current
        current.output += text
      else
        @write text

    text: (text) ->
      current = @getCurrentNode()
      if current.collect
        current.children.push text
        return

      # escape text
      text = decodeEntities text
      text = text.replace /^(\d+)\.\s/m, (m, num) -> num + "\\. "
      @_write text

    getCurrentNode: ->
      @_.stack[@_.stack.length-1]

    # get parent node.  If tag given, return first parentnode with that tag
    getParentNode: (tag) ->
      if tag
        for i in [@_.stack.length-2..0]
          if @_.stack[i].tag is tag
            return @_.stack[i]

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

      if not current.collect
        @_write(s)

        if spec.hasCloser is false
          @flush()
      else
        current.collect = true

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
        data = data.replace(/\n/g, "\n"+indent)
        data = data.replace(/\s+$/, "\n")

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

      if not current.collect
        @_write(s)
        @flush()

      if spec.next
        @spec_stack.pop()

  writer = new MarkdownWriter()

  debug "done setup html to markdown"

  CKEDITOR.plugins.add 'markdownwysiwyg', {
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

    tools: { wrapped }
  }

  pluginPath = CKEDITOR.plugins.getPath('markdownwysiwyg')


)()
