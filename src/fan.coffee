Minimist = require 'minimist'
Gpio     = require 'rpi-gpio'
GpioP    = Gpio.promise
fs       = require 'fs/promises'
Notify   = require 'sd-notify'

Gpio.setMode  GpioP.MODE_BCM


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
      d: 'delay'
      h: 'help'
      v: 'version'
      d: 'debug'
    default:
      max: 85
      min: 80
      pin: 14
      delay: 2
    unknown: (flag) =>
      return true unless flag[0] is '-'
      console.error "Unknown flag: #{flag}"
      process.exit 2
  args.max = parseInt args.max
  args.min = parseInt args.min
  args.pin = parseInt args.pin
  args.delay = parseInt args.delay
  unless args.debug
    log = ->
  log args if args.debug

  setInterval ->
    temp = await getTemp()
    log "#{temp}°C" if args.debug
    try
      if temp >= args.max and state isnt on
        await switchFan args.pin, on
      if temp <= args.min and state isnt off
        await switchFan args.pin, off
    catch err
      console.error err
  , args.delay * 1000

  Notify.ready()

do main
