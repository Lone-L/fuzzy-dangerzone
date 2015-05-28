ssid = "27MHZCON";
pass = "12345";
port = 133;
esp_server_ip = "192.168.4.1";

data = "15"
data_length = 2;
wifi.setmode(wifi.STATION);

uart.setup(0, 9600, 8, 1, 1, 0);



-- connecting to wifi
function connect_wifi()
	addr = wifi.sta.getip();
	
	if (addr == nill or addr = "0.0.0.0") then
		wifi.sta.config(ssid, pass);
		wifi.sta.connect();
	else 
		print("Connected to" .. ssid )
	end 
	print(wifi.sta.getip())
end 


-- connect to UDP server
function connect_UDP()
tmr.alarm(0, 1000, 1, function()
 	socket = net.createConnection(net.UDP, 0);
	--socket:on("receive", function(socket, data) print(data) )
	socket:on("receive", function(socket, data) print(data) end);
	socket:on("disconnection"), function (socket) connect_wifi() connect_UDP() end);
	socket:on("connection"), function tmr.stop(0) end);
	socket:connect(port, esp_server_ip); -- connect to the esp on the car
end
tmr.alarm(1, 1000, 1, connect_UDP);

function send() 
	socket:send(data);
end 

function readSerial() 
	UART.ON("data", data_length, 
			function (d) 
				data = d; 


