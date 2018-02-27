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

var Controller = require('./controller.js');
var mqtt = require('mqtt');
var express = require('express');
var cron = require('node-cron');

var controller = new Controller();
var mqttClient = mqtt.connect(MQTT_SERVER);
var app = express(); 

var MQTT_SERVER = 'mqtt://118.139.51.83';

var PROFILE_ON = false;
var SURVEILLANCE_ON = false;
var DOOR_IS_OPEN = false;
var LIGHT_ON = false;
var CURRENT_BRIGHTNESS = 100;
var CURRENT_COLOR_R = 255;
var CURRENT_COLOR_G = 255;
var CURRENT_COLOR_B = 255;
var CURRENT_AMBIENT_LIGHT = 0;
var PROFILE_COLOR_R = 0;
var PROFILE_COLOR_G = 0;
var PROFILE_COLOR_B = 0;
var LIGHT_AUTO_OFF_TIME = '';
var LIGHT_AUTO_DOOR = false;
var LIGHT_AUTO_ON_AMBL = 100;
var LIGHT_MAX_BRIGHTNESS = 100;
var LIGHT_MAX_BR_TIME = 0;
var TRIGGER_LIGHT = false;
var CURRENT_STEP = 0;

var intrusion_history = [];

var dimLightTask = null;
var offLightTask = null;

// ===== REST API =====

function jsonResponse(status, data, message) {
        var json = {
                'status': status,
                'payload': data,
                'message': message
        };
        return json;
}

var router = express.Router();

router.route('/intrusion/:timestamp')
    .get(function(req, res) {
            res.sendFile('/home/pi/as3/webcam/' + req.params.timestamp + '.jpg');
    });

router.route('/intrusion')
    .get(function(req, res) {
            if (intrusion_history.length == 0)
                    res.json(jsonResponse('fail', null, 'Not found'));
            else
                    res.json(jsonResponse('success', intrusion_history, null));
    });


// ===== MQTT =====

mqttClient.on('connect', function() {
        mqttClient.subscribe('command/color');
        mqttClient.subscribe('command/brightness');
        mqttClient.subscribe('command/profile/on');
        mqttClient.subscribe('command/profile/off');
        mqttClient.subscribe('command/surveillance/on');
        mqttClient.subscribe('command/surveillance/off');
});

function parseMQTTMessage(topic, message) {
        switch(topic.toString())
        {
                case 'command/color':
                        obj = JSON.parse(message.toString());
                        controller.setRGBLight(obj.red, obj.green, obj.blue);
                        if (obj.red == 0 && obj.green == 0 && obj.blue == 0)
                                LIGHT_ON = false;
                        else
                                LIGHT_ON = true;
                        CURRENT_COLOR_R = obj.red;
                        CURRENT_COLOR_G = obj.green;
                        CURRENT_COLOR_B = obj.blue;
                        CURRENT_BRIGHTNESS = obj.brightness;
                        break;
		        case 'command/brightness':
			            obj = JSON.parse(message.toString());
			            var dimmer = obj.brightness / 100;
			            controller.setRGBLight(Math.round(CURRENT_COLOR_R * dimmer),
				            Math.round(CURRENT_COLOR_G * dimmer), 
				            Math.round(CURRENT_COLOR_B * dimmer));
			            CURRENT_BRIGHTNESS = obj.brightness;
			            break;
                case 'command/profile/on':
                        obj = JSON.parse(message.toString());
                        PROFILE_ON = obj.profile_on;
                        LIGHT_AUTO_OFF_TIME = obj.light_auto_off_time;
                        LIGHT_AUTO_DOOR = obj.light_auto_door;
                        PROFILE_COLOR_R = obj.light_color_r;
                        PROFILE_COLOR_G = obj.light_color_g;
                        PROFILE_COLOR_B = obj.light_color_b;
                        LIGHT_AUTO_ON_AMBL = obj.light_auto_on_ambl;
                        LIGHT_MAX_BRIGHTNESS = obj.light_max_brightness;
                        LIGHT_MAX_BR_TIME = obj.light_max_br_time;
                        TRIGGER_LIGHT = false;
                        setLightDimSchedule();
                        setLightOffSchedule();
                        break;
                case 'command/profile/off':
                        PROFILE_ON = false;
                        LIGHT_AUTO_OFF_TIME = '';
                        LIGHT_AUTO_DOOR = false;
                        PROFILE_COLOR_R = 0;
                        PROFILE_COLOR_G = 0;
                        PROFILE_COLOR_B = 0;
                        LIGHT_AUTO_ON_AMBL = 0;
                        LIGHT_MAX_BRIGHTNESS = 0;
                        LIGHT_MAX_BR_TIME = 0;
			            TRIGGER_LIGHT = false;
                        if (offLightTask != null)
                                offLightTask.destroy();
                        if (dimLightTask != null)
                                dimLightTask.destroy();
                        break;
                case 'command/surveillance/on':
                        SURVEILLANCE_ON = true;
                        break;
                case 'command/surveillance/off':
                        SURVEILLANCE_ON = false;
                        break;
                default:
                        console.log('error: unknown topic');
        }
}

mqttClient.on('message', function(topic, message) {
        console.log(topic.toString() + ': ' + message.toString());
        parseMQTTMessage(topic, message);
});


// ===== CONTROLLER =====

function setLightOffSchedule()
{
        var time = LIGHT_AUTO_OFF_TIME;
        var tok = time.split(":");
        var hour = parseInt(tok[0]);
        var minutes = parseInt(tok[1]);
        offLightTask = cron.schedule(minutes + ' ' + hour + ' * * *', function() {
                console.log('turning off');
                controller.setRGBLight(0, 0, 0);
                mqttClient.publish('event/color/off', '');
        });
        console.log('schedule is set to turn off at HH:mm');
}

function setLightDimSchedule()
{
        CURRENT_STEP = 0;
        var timeStep = LIGHT_MAX_BR_TIME / 5;
        dimLightTask = cron.schedule('*/' + timeStep  + ' * * * *', function() {
                console.log('dimming...');
                CURRENT_STEP += 1;
                var brightStep = LIGHT_MAX_BRIGHTNESS / LIGHT_MAX_BR_TIME;
                CURRENT_BRIGHTNESS = brightStep * CURRENT_STEP;
                var dimmer = CURRENT_BRIGHTNESS / 100;
                //heeeereeee!!
		        controller.setRGBLight(PROFILE_COLOR_R * dimmer,
                        PROFILE_COLOR_G * dimmer,
                        PROFILE_COLOR_B * dimmer);
                var lightState = { 'level': CURRENT_BRIGHTNESS };
                mqttClient.publish('event/color/on', JSON.stringify(lightState));
                // stop cron somehow
                if (CURRENT_BRIGHTNESS == LIGHT_MAX_BRIGHTNESS)
                {
                        dimLightTask.stop();
                        console.log('the dimmer has stopped');
                }
        }, false);
        console.log('schedule is set to dim');
}

function controlLight() {
        if (CURRENT_AMBIENT_LIGHT >= LIGHT_AUTO_ON_AMBL)
        {
                TRIGGER_LIGHT = true;
                dimLightTask.start();
		        console.log('dimmer started');
        }
}

controller.on('controllerReady', function() {
        console.log('Controller ready!');
        setInterval(controller.getAmbientLightData, 1000);
});


controller.on('ambientLightChange', function(ambientLightData) {
        CURRENT_AMBIENT_LIGHT = ambientLightData.level;
        mqttClient.publish('event/ambientLight', JSON.stringify(ambientLightData));
        console.log('Publishing new ambient light value...');
        if (LIGHT_ON == false && PROFILE_ON == true && TRIGGER_LIGHT == false)
        {       
		    console.log('controlling light');
		    controlLight();
	    }
});

controller.on('doorStateChange', function(doorData) {
        if (doorData.doorState == 'open')
        {
                DOOR_IS_OPEN = true;
                if (LIGHT_ON == false && PROFILE_ON == true && LIGHT_AUTO_DOOR == true)
                {
                        var dimmer = LIGHT_MAX_BRIGHTNESS / 100;
                        controller.setRGBLight(PROFILE_COLOR_R * dimmer,
                                PROFILE_COLOR_G * dimmer,
                                PROFILE_COLOR_B * dimmer);
                        var lightState = { 'level': CURRENT_BRIGHTNESS };
                        mqttClient.publish('event/color/on', JSON.stringify(lightState));

                }
                if (SURVEILLANCE_ON == true)
                {
                        var timestamp = Date.now();
                        var command = './webcam.sh ' + timestamp;
                        cmd.run(command);
                        intrusion_history.push({ 'eventData': doorData, 'timestamp': timestamp });
                        mqttClient.publish('event/intrusion', '');
                }
        }
        else if (doorData.doorState == 'close')
        {
                DOOR_IS_OPEN = false;
                if (LIGHT_ON == true && PROFILE_ON == true && LIGHT_AUTO_DOOR == true)
                {
                        controller.setRGBLight(0, 0, 0);i
                        mqttClient.publish('event/color/off', '');
                }
        }
        mqttClient.publish('event/doorState', JSON.stringify(doorData));
        console.log('Publishing new door state...');
});

controller.initController();

app.use('/api', router);
app.listen(process.env.PORT || 8080);
console.log('REST API listening now!');

