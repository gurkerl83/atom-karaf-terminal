util = require 'util'
path = require 'path'
os = require 'os'
fs = require 'fs-plus'
spawn = require('child_process').spawn

debounce = require 'debounce'
Terminal = require './vendor/term.js'

keypather = do require 'keypather'

{$, View} = require 'atom-space-pen-views'

last = (str)-> str[str.length-1]

renderTemplate = (template, data)->
  vars = Object.keys data
  vars.reduce (_template, key)->
    _template.split(///\{\{\s*#{key}\s*\}\}///)
    .join data[key]
  , template.toString()

class KarafTerminalView extends View

  @content: ->
    @div class: 'atom-karaf-terminal'

  constructor: (@opts={})->
    opts.shell = process.env.SHELL or '/bin/sh'
    opts.shellArguments or= ''

    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    opts.cwd = fs.absolute(opts.cwd or
        atom.project.getPaths()[0] or
        editorPath or process.env.HOME)
    super

  ###
  createPTY: (args=[]) ->
    package_path = atom.packages.resolvePackagePath 'atom-karaf-terminal'
    pty = fs.absolute "#{package_path}/src/terminal.rb"
    rbx = fs.absolute "~/.atom/karaf/bin/rbx"
    console.log pty
    options =
      cwd: @opts.cwd
      env:
        "PS1": "\\w\\$ "
        "PS2": "> "
        "PS4": "+ "
        "TERM": "xterm-color"
        "HOME": process.env.HOME
      stdio: 'pipe'

    spawn rbx, [pty, @opts.shell], options
  ###

  createPTY: (args=[]) ->

    process.env['JAVA_HOME'] = path.resolve(__dirname + '/jre/Contents/Home');


    options =
      cwd: @opts.cwd

      env:
        "PS1": "\\w\\$ "
        "PS2": "> "
        "PS4": "+ "
        "TERM": "xterm-color"
        "HOME": process.env.HOME
      stdio: 'pipe'

    ###
    options =
      cwd: process.cwd()
      env: process.env
      stdio: 'inherit'
    ###

    #spawn rbx, [pty, @opts.shell], options
    spawn path.resolve(__dirname + '/karaf/bin/karaf'), [@opts.shell], options

  initialize: (@state) ->
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, runCommand, colors, cursorBlink, scrollback} = @opts
    args = shellArguments.split(/\s+/g).filter (arg)-> arg

    @ptyProcess = @createPTY args
    [@ptyRead, @ptyWrite] = [@ptyProcess.stdin, @ptyProcess.stdout]

    ###
    @ptyWrite.on 'data', (data) =>
      @terminal.write data.toString()
    ###

    ###
    @ptyWrite.on 'data', (data) =>
      dataString = data.toString()

      commands = dataString.split("\r");
      lines = dataString.split("\n");

      linesWrite = []

      for i in [0...lines.length-1] by 1
          debugger;

          lines[i] = lines[i].concat("\n");
          #lines[i] = lines[i].concat("\r");

      debugger;

      if commands[0].length == 1 or commands[0] == "\r"
        @terminal.write data.toString()
      else
         @terminal.write lines
    ###

    @ptyWrite.on 'data', (data) =>
      dataString = data.toString()

      lines = dataString.split("\n");

      if lines[0].length == 1 or lines[0] == "\r"
        console.log("Command determined")
      else
        for i in [0...lines.length-1] by 1
          debugger;
          lines[i] = lines[i].concat("\n");

      debugger;

      @terminal.write lines

    @ptyProcess.on 'exit', (code, signal) => @destroy()

    colorsArray = (colorCode for colorName, colorCode of colors)

    @terminal = terminal = new Terminal {
      useStyle: no
      screenKeys: yes
      colors: colorsArray
      cursorBlink, scrollback, cols, rows
    }

    terminal.end = => @destroy()

    terminal.on 'data', (data) => @input data

    terminal.open this.get(0)

    #@input "#{runCommand}#{os.EOL}" if runCommand
    terminal.focus()

    @attachEvents()
    @resizeToPane()

  input: (data) ->
    @ptyRead.write data

  resize: (cols, rows) ->
# TODO: previously: @ptyProcess.send {event: 'resize', rows, cols}

  titleVars: ->
    bashName: last @opts.shell.split '/'
    hostName: os.hostname()
    platform: process.platform
    home    : process.env.HOME

  getTitle: ->
    @vars = @titleVars()
    titleTemplate = @opts.titleTemplate or "({{ bashName }})"
    renderTemplate titleTemplate, @vars

  attachEvents: ->
    @resizeToPane = @resizeToPane.bind this
    @attachResizeEvents()
# @command "atom-karaf-terminal:paste", => @paste()

  paste: ->
    @input atom.clipboard.read()

  attachResizeEvents: ->
    setTimeout (=>  @resizeToPane()), 10
    @on 'focus', @focus
    $(window).on 'resize', => @resizeToPane()

  detachResizeEvents: ->
    @off 'focus', @focus
    $(window).off 'resize'

  focus: ->
    @resizeToPane()
    @focusTerm()
    super

  focusTerm: ->
    @terminal.element.focus()
    @terminal.focus()

  resizeToPane: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @terminal
    return if @terminal.rows is rows and @terminal.cols is cols

    @resize cols, rows
    @terminal.resize cols, rows
    pane = atom.workspace.getActivePane()
# TODO: Fixed deprecation on atom.workspaceView.getActivePaneView()
# but this code does not translate:
# atom.views.getView(pane).css overflow: 'visible'

  ###
  resizeToPane: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @terminal
    return if @terminal.rows is rows and @terminal.cols is cols

    @resize cols, rows
    @terminal.resize cols, rows
    atom.views.getView(atom.workspace).style.overflow = 'visible'
  ###

  getDimensions: ->
    fakeCol = $("<span id='colSize'>&nbsp;</span>").css visibility: 'hidden'
    if @terminal
      @find('.terminal').append fakeCol
      fakeCol = @find(".terminal span#colSize")
      cols = Math.floor (@width() / fakeCol.width()) or 9
      rows = Math.floor (@height() / fakeCol.height()) or 16

      debugger;

      fakeCol[0].remove()
    else
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 14

    {cols, rows}

  ###
  getDimensions: ->
    fakeRow = $("<div><span>&nbsp;</span></div>").css visibility: 'hidden'
    if @terminal
      @find('.terminal').append fakeRow
      fakeCol = fakeRow.children().first()
      cols = Math.floor (@width() / fakeCol.width()) or 9
      rows = Math.floor (@height() / fakeCol.height()) or 16
      fakeCol.remove()
    else
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 14

    {cols, rows}
  ###

  destroy: ->
    @detachResizeEvents()
    @terminal.destroy()
    parentPane = atom.workspace.getActivePane()
    if parentPane.activeItem is this
      parentPane.removeItem parentPane.activeItem
    @detach()


module.exports = KarafTerminalView
