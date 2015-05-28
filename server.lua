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
PERIOD = 235000;--500;

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

-- setting access point
function setAP() 
	print("setting AP SSID: " .. cfg.ssid .. "PASS: " .. "Can't tell :D");
	wifi.setmode(wifi.STATIONAP);
	wifi.ap.config(cfg);
end 

--Setting up AP
setAP();

--Setting up UDP server
server = net.createserver(net.UDP, serverTimeout);


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
		conn:on("receive", function(conn, d) data = d print(data) end); -- store d in global variable data and print data
		--conn:send(data) -- echo test									-- event driven
		end
	) 
end 


-- motion and steering are coded as follows
-- motion can range between 0 - 9, 0 being MIN (max speed backwards) and 9 being MAX(max speed forwards)
-- the value 5 represents IDLE_WIDTH_M
-- steering can range between 0 - 9, 0 being the MIN (max turning left) and 9 being Max( max turning right)
-- 5 represents straight IDLE_WIDTH_S
-- note this function changes the global variables steering and motion which are used to generate the wave form
function modifyMotionParameters()
	getData();

	m = string.byte(data, 1) - numeric_char_0; -- get numeric value of motion code
	s = string.byte(data, 2) - numeric_char_0; -- get numeric value of steering code

	-- TODO: modify to add different speeds
	if (m == 0) then
		motion = MIN;
	elseif (m == 1) then 
		motion = IDLE_WIDTH_M;
	elseif (m == 2) then
		motion = MAX;
	else 
		motion = IDLE_WIDTH_M;
	end 


	-- modify steering global variable
	if (s == 5 or s > 9 or s < 0) then
		steering = IDLE_WIDTH_S;
	else 
		steering = min + steering_resolution * s; 
	end 
end 

start = tmr.now();

tmr.alarm(1, 22, 1, function() 
	if (PERIOD - start - tmr.now() > 0) then
		waveform();
	else 
		start = tmr.now();
	end 
end)

tmr.alarm(1, PERIOD, 1, modifyMotionParameters);

	

