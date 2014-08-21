# Copyright (c) 2014 Michele Bini
#
# This program is available under the terms of the MIT License
  
module.exports = ((x)-> x.clone())
  version: "makefile-coffee 0.3.0"

  RegExp: RegExp
  fs: require 'fs'
  # cp: require 'child_process'
  touch: require 'touch'
  execSync: require 'execSync'
  setTimeout: setTimeout
  clearTimeout: clearTimeout

  ruleToRx: (x)->
    # From Oriol, stackoverflow.com: http://stackoverflow.com/questions/2593637/how-to-escape-regular-expression-in-javascript
    escaperx = (str)->
       str.replace /[.^$*+?()[{\\|\]-]/g, '\\$&'
      
    new @RegExp("^" + escaperx(x).replace("%", "(.*)") + "$")

  maxDepth: 7

  rule: ->
    args = (x for x in arguments)
    target = null
    deps = [ ]
    task = null
    opts = { }
    while args.length
      x = args.shift()
      t = typeof x
      if t is "string"
        unless target?
          target = x
        else
          deps.push x
      else if t is "function"
        task = x
      else if t is "object"
        opts[k] = v for k,v of x
    if /%/.test target
      @trace "Adding rule for #{target}"
      @rules.push { target, deps, opts, task, rx: @ruleToRx(target) }
    else
      delete @targets[target]
      @trace "Adding rule for #{target}"
      @targets[target] = { deps, opts, task }
    @

  'var': ->
    args = (x for x in arguments)
    name = args.shift()
    delete @vars[name]
    if args.length > 0
      @vars[name] = args.join(' ')
    else
      @vars[name] = name
    @

  sh: ->
    args = (x for x in arguments)
    cmdparts = []
    opt = { }
    for x in args
      t = typeof x
      if t is 'string'
        cmdparts.push x
      else
        opt[k] = v for k,v of x
    cmd = cmdparts.join(' ')
    if opt.out
      cmd = cmd + ' >' + opt["out"]
    if opt.in
      cmd = cmd + ' <' + opt["in"]
    @show cmd
    @execSync.run cmd unless @testRun

  vars: [ ]
  rules: [ ]
  targets: { }

  clone: ->
      y = do ({ rule } = @)-> ->
        rule.apply y, arguments
      y[k]=v for k,v of @; y
      y.vars = @vars.slice(0)
      y.rules = @rules.slice(0)
      y.targets  = do (x = { })=> x[k] = v for k,v of @targets;  x
      y

  process: process

  echo: ->
    args = [ x for x in arguments ]
    @process.stdout.write args.join(' ') + "\n"
    @

  setup: (setup)->
    setup.apply @
    @

  setupMakefile: (f)->
    # Setup a Makefile with traditional syntax.  Only a subset of the syntax is currently supported.
    if @fs.existsSync f
      try
        c = @fs.readFileSync(f)
        unless (c = c.toString())?
          throw "Could not decode file"
      catch error
        @error "Could not read #{f}: #{error}"
      lineno = 0
      add = (heading, rule)=>
        rule = do (rule)->
          compile = (x)->
            return (->) if x is ""
            x = x.split(/([$][(][^)]*[)])/)
            y = [ ]
            y = y.concat z.split(/([$][^(])/) for z in x
            ->
              x = for z in y
                if (match = /^[$][(]([^)]*)[)$]/.exec z)?
                  n = match[1]
                  @v[n]
                else if (match = /^[$](.)$/.exec z)?
                  b = match[1]
                  if b is "@"
                    @out
                  else if b is "^"
                    @deps.join ' '
                  else if b is "<"
                    @in
                  else
                    @error "Unknown variable identifier in #{f}: '$#{b}'"
                else
                  z
              cmd = x.join('')
              @show cmd
              @execSync.run cmd unless @testRun
          rule = (compile x for x in rule)
          ->
            x.call @ for x in rule
        args = [ heading[1] ]
        args = args.concat(heading[2].trim().split(/\ +/))
        args.push rule
        @.apply @, args
      heading = null
      rule = [ ]
      for line in c.split "\n"
        lineno++
        line = line.trim()
        if (match = /^([^\ ]+)=(.*)$/.exec line)?
          @vars[match[1]] = match[2]
        else if (match = /^([^\ ]*):(.*)$/.exec line)?
          if heading?
            add heading, rule
            rule = [ ]
          heading = match
        else
          rule.push line
      if heading?
        add heading, rule
    else
      @error "File '#{f}' does not exist!"

  error: (msg)->
    @echo msg
    @process.exit(1)
    throw "Could not exit after error: #{msg}"

  assertTrue: (msg, cond)->
    throw "Internal error: #{msg}" unless cond

  info: (msg)->
    if @verboseness >= 1
      @echo msg
    @

  show: (msg)->
    if @verboseness >= 0
      @echo msg
    @

  trace: (msg)->
    if @verboseness >= 2
      @echo msg
    @

  debug: (msg)->
    if @verboseness >= 3
      @echo msg
    @

  makeNow: (target)->
    entry = @target[target]
    @depsRequired or= { }
    if entry?
      for dep in entry.deps
        if @depsRequired[dep]?
          @info "Ignored circular or duplicate dependency: #{dep}"
        else
          true
    @

  make: (target)->
    (@toMake or= {})[target] = 1

  verboseness: 0

  options:
    watch: (args)-> @action = 'watchAction'
    verbose: (args)-> @verboseness++
    quiet: (args)-> @verboseness = -1
    delay: (args)-> @buildDelay = args.shift()
    test: (args)-> @testRun = true
    f: (args)->
      if @defaultMakefile?
        @defaultMakefile = null?
      (@makefiles ?= [ ]).push args.shift()

  processOption: (name, args)->
    if (x = @options[name])?
      x.call @, args
    else
      @error "Unrecognized option: --#{name}"

  action: 'buildAction'

  watchAction: ->
    timeout = null
    @buildAction() # This should be moved for production
    @fs.watch '.', (event, filename)=>
      @trace "Event for #{filename}"
      if timeout
        @clearTimeout timeout
        timeout = null
      timeout = @setTimeout((=> @buildAction()), @buildDelay)
    @

  buildAction: ->
    @targetsChecked = { }
    @targetsBuilt = { }
    @tryMake x for x of @toMake
    @

  fileExists: (x)->
    @fs.existsSync(x)

  depExists: (x)->
    # Dependencies that have been built already are assumed to exist!
    @targetsBuilt[x] or @fileExists(x)

  fileTime: (f)->
    try
      s = @fs.statSync(f)
    catch error
      return null
    s.mtime

  depTime: (f)->
    s = @fs.statSync(f)
    s.mtime

  isTargetNewer: (target, deps)->
    return false unless (t = @fileTime target)?
    @debug "deps: " + target
    for d in deps
      @assertTrue "Dependency #{target} doesn't have a time", (tt = @depTime d)?
      return false if t <= tt
    @trace "newer"
    true

  lib:
    constants: require ("constants")

  touchFile: (f)->
    return if @testRun
    @touch.sync(f)
    # try
    #   fd = @fs.openSync(f, @lib.constants.O_RDWR)
    # catch e
    #   throw e
    # @fs.closeSync(fd)

  tryBuild: (target, deps, task, soft)->
      @debug "Try to build #{target}"
      @debug "Complain if some dependencies are missing."
      for xx in deps
        unless @depExists(xx)
          (if soft then @trace else @error).call @, "A required dependency is missing: #{xx}"
          return
      # Do nothing if target is newer than all dependencies
      unless @isTargetNewer(target, deps)
        # Otherwise build our target
        @trace "Building target: #{target} with deps #{deps.join(',')}"
        @dep = deps
        @in = deps[0]
        @out = target
        fileDidExistBefore = @fileExists target
        try
          task.apply @
          @touchFile(target)
        catch error
          unless fileDidExistBefore
            try
              @fs.unlinkSync(target)
            catch error2
              true
          throw error

  tryMake: (x, depth = 0)->
    depth++
    return if depth > @maxDepth
    if @targetsChecked[x]?
      @trace "#{x} already checked, skipping"
      return
    @info "Checking status of #{x}"
    @targetsChecked[x] = 1
    if (t = @targets[x])?
      for xx in t.deps
        @tryMake xx, depth
      @tryBuild(x, t.deps, t.task)
    else
      @debug "No explicit target found, checking rules for #{x}"
      for r in @rules
        if (m = r.rx.exec x)?
          @trace "Rule #{r.target} <- #{r.deps[0] ? "''"} matches!"
          deps = (d.replace "%", m[1] for d in r.deps)
          for xx in deps
            @tryMake xx, depth
          @tryBuild(x, deps, r.task, true)
          @debug "Rule #{r.target} <- #{r.deps[0] ? "''"} matches! DONE"

  performAction: ->
    @v = @vars
    if !@makefiles? and @defaultMakefile?
      @makefiles = [ @defaultMakefile ]
    if @makefiles?
      @setupMakefile x for x in @makefiles
    unless @toMake?
      lastTarget = null
      lastTarget = k for k,v of @targets
      @error "No targets defined!" unless lastTarget?
      @make lastTarget
    @[@action].apply @

  processOptions: (args)->
    while args.length
        x = args.shift()
        if (m = /^--(.*)$/.exec(x))?
          if m[1] is ''
            break
          @processOption m[1], args
        else if (m = /^-(.)$/.exec(x))?
          @processOption m[1], args
        else
          @make x
    while args.length
        x = args.shift()
        @make x
    @

  withProcessArgs: (cb)->
    { process } = @
    # Extract correct argument list
    { argv } = process
    args = if /([/]|^)(node(js)?|coffee)([.]exe)?$/i.test argv[0] then argv.slice(1) else argv.slice(0)
    progname = args.shift()
    cb.call @, args, { progname }
    @

  runWithArgs: (args, setup)->      
    @processOptions(args).setup(setup).performAction()

  run: (setup)->
    @withProcessArgs (args)->
      @runWithArgs(args, setup)

  runWithArgs: (args)->
    @processOptions(args).performAction()

  runStandalone: ({ process })->
    @defaultMakefile = 'Makefile'
    @process = process if process?
    @withProcessArgs (args)->
      @runWithArgs args
