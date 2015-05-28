---SERVER---
------------
--SETTINGS--

cfg = {};
cfg.ssid = "27MHZCON"; -- SSID
cfg.pass = "12345"; -- PASS

serverTimeout = 28000;
-----------------------------
--WAVEFORM--
--CONSTANT--
waveform_pin = 3;
PERIOD = 23;--500;

IDLE_WIDTH_M = 1500;
IDLE_WIDTH_S = 1220;

PULSE_GAP = 200;

MAX = 1350;
MIN = 1100;

steering_resolution = 15; --(MAX_STEERING_PULSE - MIN_STEERING_PULSE) / 10  -- using a resolution of 10.
motion = IDLE_WIDTH_M; -- will change depending on code received from controler
steering = IDLE_WIDTH_S; -- will change depending on code received from controller

numeric_char_0 = string.byte('0');


local data;


function setAP() 
	print("setting AP SSID: " .. cfg.ssid .. "PASS: " .. "Can't tell :D");
	wifi.setmode(wifi.STATIONAP);
	wifi.ap.config(cfg);
end 


-- listing access point function 
local listap = function(t) 
	if (type(t) ~= "table") then
		print("not table");
		return;
	end;

	for key,value in pairs(t) do
		tmr.wdclr();
        --if string.find(key , "myssid") then
        local _SSID = key 
        local _BSSID=""
        local _RSSI=""
        local _enc=""
        local _chan=""
        _enc, _RSSI, _BSSID, _chan = string.match(value,
            "(%d),(-?%d+),(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x),(%d+)")
        print(_SSID..":\t\t".._BSSID..",".._RSSI.."\n")
        _enc=nil _chan=nil
        _SSID=nil _RSSI=nil _BSSID=nil
        --end
    end
end 

--Setting up AP
setAP();

--Setting up TCP server
server = net.createserver(net.UDP, serverTimeout);

--list AP test chode
wifi.sta.getap(listap);
listap=nil;

-- generate waveform 
gpio.mode(waveform_pin, gpio.OUTPUT);
gpio.write(waveform_pin, gpio.HIGH);

function waveform()

	tmr.wdclr() -- clear watch dog

	gpio.write(waveform_pin,gpio.LOW);
	tmr.delay(PULSE_GAP);

	--Wait for the motion width
	gpio.write(waveform_pin,gpio.HIGH);
	tmr.delay(motion);

	gpio.write(waveform_pin,gpio.LOW);
	tmr.delay(PULSE_GAP);

	--Wait for steering width
	gpio.write(waveform_pin,gpio.HIGH);
	tmr.delay(steering);

	gpio.write(waveform_pin,gpio.LOW);
	tmr.delay(PULSE_GAP);

	--reset to high
	gpio.write(waveform_pin,gpio.HIGH);
end 

function getData()
	-- listen on port 133
	server:listen(133, function(conn)
		conn:on("receive", function(conn, d) data = d print(data) end);
		--conn:send(data) -- echo test
		end
	) 
end 

function modifyAlarm()
	getData();

	m = string.byte(data, 1) - numeric_char_0;
	s = string.byte(data, 2) - numeric_char_0;

	if (m == 0) then
		motion = MIN;
	elseif (m == 1) then 
		motion = IDLE_WIDTH_M;
	elseif (m == 2) then
		motion = MAX;
	else 
		motion = IDLE_WIDTH_M;
	end 

	if (s == 5 or s > 9 or s < 0) then
		steering = IDLE_WIDTH_S;
	else 
		steering = min + steering_resolution * s;
	end 
end 

start = tmr.now();

tmr.alarm(1, PERIOD, 1, function() 
	if (PERIOD - start - tmr.now() > 0) then
		waveform();
	else 
		start = tmr.now();
	end 
end)

tmr.alarm(1, PERIOD, 1, modifyAlarm);

	

