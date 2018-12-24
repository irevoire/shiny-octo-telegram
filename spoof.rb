require_relative "menu"

if ARGV.size != 1
	puts "Usage: #{__FILE__} interface"
	exit
end

$INTERFACE = ARGV[0]

if Process.uid != 0
	puts "Script need to be run as root"
	exit 
end

require_relative "ip/iproute2"
require_relative "ip/ifconfig"
networkManager = nil
if Iproute2.available?
	puts "using iproute2"
	networkManager = Iproute2
elsif Ifconfig.available?
	puts "using ifconfig"
	networkManager = Ifconfig
else
	puts "You should install ifconfig or iproute2"
	exit
end

base = nil
ipaddr = nil
router = nil

ipaddr = networkManager.ip $INTERFACE
$MAC_ADDR = networkManager.mac $INTERFACE
# TODO base should depend on the br
base = ipaddr.split(".")[0..2].append("*").join(".")
router = networkManager.router $INTERFACE

puts "Your mac address is : #{$MAC_ADDR}"

require_relative "nmap"
if !Nmap.available?
	puts "You should install nmap"
	exit
end

puts "Calling nmap"
menu = Nmap.getDevice base

at_exit do
	puts "Your mac address before exit is : #{networkManager.mac $INTERFACE}"
	networkManager.mac $INTERFACE, $MAC_ADDR
	puts "Your mac address after exit is : #{networkManager.mac $INTERFACE}"
end

position = 0
menu = Menu.new menu

menu.draw(position)
while ch = menu.get_char
	case ch
	when "k", :up
		position -= 1
	when "j", :down
		position += 1
	when "r"
		menu.clear
		puts "Calling nmap"
		menu.menu = Nmap.getDevice base
		menu.draw position
	when "\n", " "
		puts menu.menu[position]
		mac = menu.menu[position].split("\t")[0]
		networkManager.mac $INTERFACE, mac
		`ping #{router} -i 0`
	when 'x'
		exit
	end

	position = menu.size - 1 if position < 0
	position = 0 if position >= menu.size
	menu.reset
	menu.draw(position)
end
