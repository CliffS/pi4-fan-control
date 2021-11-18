# pi4-fan-control

[issues]: https://github.com/CliffS/pi4-fan-control/issues
[casefan]: https://www.raspberrypi.com/products/raspberry-pi-4-case-fan/

### Run the fan when the temperature gets high

This module is designed to be installed globally and will compile
to a single executable called **fan** which will probably be in
`/usr/local/bin`.

The executable can be used to turn the fan on or off but is
primarily designed to be run out of systemd to monitor the
temperature and turn the fan on and off as necessary.

The program was written for the pi4 with the official case fan
but should work on any fan with its control set to a single gpio
pin.

It will work on Ubuntu on the pi4 where none of the _official_ solutions
seems to do the job.  For wiring of the case fan, please see the page
at [raspberrypi.com][casefan].

## Install

    npm install -g pi4-fan-control

## Usage

    fan [options] [on|off]
        Run without [on|off], the fan program will turn the fan on and off
          depending on temperature
        fan on  - Turn the fan on and exit
        fan off - Turn the fan off and exit
        options:
           -h --help:       Show this message
           -v --version:    Display version and exit
           -x --max:        Temperature to turn the fan on    (default: 85)
           -n --min:        Temperature to turn the fan off   (default: 80)
           -p --pin         Pin to use for control            (default: 14)
           -y --delay       Polling frequency in seconds      (default:  2)
           -s --show        Display on/off messages on stdout (default: off)
           -d --debug       Turn on debugging mode            (default: off)

## Running from systemd

You will need to create a service file: `/etc/systemd/system/pi4-fan.service`.

The contents should be something like:

    [Unit]
    Description=Fan controller for the pi4

    [Service]
    Type=notify
    User=root
    Group=root
    ExecStart=/usr/local/bin/fan
    TimeoutStartSec=60
    NotifyAccess=all
    Restart=always
    KillSignal=SIGTERM
    TimeoutStopSec=20
    RestartSec=20

    [Install]
    WantedBy=multi-user.target

If you want a lower max/min temperature setting, add, for example
`--max 80 --min 72` to the ExecStart line.

If you want the fan on/off messages to be logged to the journal,
add `--show` to the ExecStart line. They can then be seen with
`sudo journalctl -xe -u pi4-fan`.

Having created this file, please run the following commands:

    $ sudo systemctl daemon-reload
    $ sudo systemctl enable pi4-fan.service
    $ sudo systemctl start  pi4-fan.service
    $ sudo systemctl status pi4-fan.service

This should show the service as running.

## Node version issue

As of the time of writing, `pkg-fetch` does not support node version 17.
Please either revert to node version 16 or run the javascript file
directly from node, rather than the executable.

## Changelog

**v1.0.0**: First public release  
**v1.0.2**: Documentation fixes only  
**v1.1.0**: Added the --show switch

## Problems

Any issues or comments would be appreciated at [Github][issues].

