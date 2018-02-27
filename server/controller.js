// Main references
// Control a simple swith in Raspberry Pi -> https://youtu.be/Bqk6M_XdIC0
// Control an RGB led in Raspberry Pi -> https://youtu.be/b4_R1eX9K6s
// Pi-blaster (PWM daemon) -> https://github.com/sarfata/pi-blaster
// Pi-blaster (Node js API) -> https://github.com/sarfata/pi-blaster.js
// GPIO and SPI in Node -> https://github.com/jperkin/node-rpio
// MCP3008 example -> https://learn.adafruit.com/raspberry-pi-analog-to-digital-converters/mcp3008
// MQTT broker for the Raspberry Pi -> http://www.switchdoc.com/2016/02/tutorial-installing-and-testing-mosquitto-mqtt-on-raspberry-pi/
// Send files through REST API -> http://expressjs.com/en/api.html#res.sendFile
// Using a webcam in Raspberry PI -> https://www.raspberrypi.org/documentation/usage/webcams/
// Scheduling jobs in node -> https://www.npmjs.com/package/node-cron
// Executing shell commands in node -> https://www.npmjs.com/package/node-cmd

var events = require('events');
var rpio = require('rpio');
var piblaster = require('pi-blaster.js');

var options = {
	gpiomem: false,
	mapping: 'physical'
};

rpio.init(options);

function Controller()
{
        var SPI_CHANNEL = 0;
        var SPI_CLOCK_DIVIDER = 250;
        var PIN_PWM_RED = 17;
        var PIN_PWM_GREEN = 27;
        var PIN_PWM_BLUE = 22;
        var PIN_SW_DOOR = 7;

        var self = this;

        events.EventEmitter.call(this);

        var ambientLight = 0;

        function pollcb(pin)
        {
                var state = rpio.read(pin) ? 'close' : 'open';
                doorData = { 'doorState' : state };
                self.emit('doorStateChange', doorData);
        }

        this.initController = function()
        {
                rpio.open(PIN_SW_DOOR, rpio.INPUT, rpio.PULL_DOWN);
                rpio.poll(PIN_SW_DOOR, pollcb);
                self.emit('controllerReady');
        };

        this.getAmbientLightData = function()
        {
                rpio.spiBegin();
                    rpio.spiChipSelect(0);
                    rpio.spiSetCSPolarity(0, rpio.LOW);
                    rpio.spiSetClockDivider(SPI_CLOCK_DIVIDER);
                    rpio.spiSetDataMode(0);

                    var cmd = 0b11 << 6;
                    cmd |= (SPI_CHANNEL & 0x07) << 3;
                    var tx = new Buffer([ cmd, 0x0, 0x0 ]);
                    var rx = new Buffer(3);
                    var out;

                    rpio.spiTransfer(tx, rx, 3);
                    out = (rx[0] & 0x01) << 9;
                    out |= (rx[1] & 0xFF) << 1;
                    out |= (rx[2] & 0x80) >> 7;
                    out &= 0x3FF;
                rpio.spiEnd();
                if (out != this.ambientLight)
                {
                        ambientLightData = { 'level': out * 100 / 1024.0 };
                        self.emit('ambientLightChange', ambientLightData);
                }
        };

        this.setRGBLight = function(red, green, blue)
        {
                piblaster.setPwm(PIN_PWM_RED, red/255);
                piblaster.setPwm(PIN_PWM_GREEN, green/255);
                piblaster.setPwm(PIN_PWM_BLUE, blue/255);
        };
}

Controller.prototype.__proto__ = events.EventEmitter.prototype;

module.exports = Controller;

