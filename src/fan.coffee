Minimist = require 'minimist'
Gpio     = require 'rpi-gpio'
GpioP    = Gpio.promise
fs       = require 'fs/promises'
Notify   = require 'sd-notify'
path     = require 'path'

Gpio.setMode  GpioP.MODE_BCM

syntax = ->
  me = 'fan'
  console.log """
    #{me} [options] [on|off]
        Run without [on|off], the #{me} program will turn the fan on and off
          depending on temperature
        #{me} on  - Turn the fan on and exit
        #{me} off - Turn the fan off and exit
        options:
           -h --help:       This message
           -v --version:    Display version and exit
           -x --max:        Temperature to turn the fan on    (default: 85)
           -n --min:        Temperature to turn the fan off   (default: 80)
           -p --pin         Pin to use for control            (default: 14)
           -y --delay       Polling frequency in seconds      (default:  2)
           -s --show        Display on/off messages on stdout (default: off)
           -d --debug       Turn on debugging mode            (default: off)
    """
  process.exit 1

getTemp = ->
  fs.readFile '/sys/class/thermal/thermal_zone0/temp'
  .then (temp) =>
    (parseFloat(temp) / 1000).toFixed 1

log = console.log

state = undefined

switchFan = (pin, onoff = off) ->
  log "Switching fan (#{pin})", if onoff then 'on' else 'off'
  GpioP.setup pin, GpioP.DIR_OUT
  .then =>
    GpioP.write pin, onoff
  .finally =>
    GpioP.destroy()
    state = onoff

main = ->
  args = Minimist process.argv[2..],
    boolean: [
      'help'
      'version'
      'show'
      'debug'
    ]
    string: [
      'max'
      'min'
      'pin'
      'delay'
    ]
    alias:
      x: 'max'
      n: 'min'
      p: 'pin'
      y: 'delay'
      h: 'help'
      v: 'version'
      s: 'show'
      d: 'debug'
    default:
      max: 85
      min: 80
      pin: 14
      delay: 2
    unknown: (flag) =>
      return true unless flag[0] is '-'
      console.error "Unknown flag: #{flag}"
      syntax()
  args.max = parseInt args.max
  args.min = parseInt args.min
  args.pin = parseInt args.pin
  args.delay = parseInt args.delay
  if args.version
    pack = path.join __dirname, '../package.json'
    pack = await fs.readFile pack
    json = JSON.parse pack
    console.log "Version is v#{json.version}"
    process.exit 1
  else if args.help
    syntax()
  else if process.geteuid() isnt 0
    console.error "This program must be run as root."
    process.exit 2
  else
    unless args.debug
      log = ->
    log args if args.debug

    switch args._.length
      when 0
        setInterval ->
          temp = await getTemp()
          log "#{temp}°C" if args.debug
          try
            if temp >= args.max and state isnt on
              console.log "Switching fan on at #{temp}°C" if args.show
              await switchFan args.pin, on
            if temp <= args.min and state isnt off
              console.log "Switching fan off at #{temp}°C" if args.show
              await switchFan args.pin, off
          catch err
            console.error err
        , args.delay * 1000
        Notify.ready()
      when 1
        switch args._[0]
          when 'on'
            await switchFan args.pin, on
          when 'off'
            await switchFan args.pin, off
          else syntax()
      else
        syntax()

do main
