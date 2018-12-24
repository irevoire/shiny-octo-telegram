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
Ip = nil
if Iproute2.available?
	Ip = Iproute2
elsif Ifconfig.available?
	Ip = Ifconfig
else
	puts "You should install ifconfig or iproute2"
	exit
end

base = nil
ip = nil
router = nil

puts "using iproute2"
ip = Ip.ip $INTERFACE
$MAC_ADDR = Ip.mac $INTERFACE
# TODO base should depend on the br
base = ip.split(".")[0..2].append("*").join(".")
router = Ip.router $INTERFACE

nmap = `nmap -sP #{base} | awk '/^Nmap/ {printf $5" "} /^MAC/ {print $3}'`
menu = nmap.lines.map { |line| line.split(" ").reverse.join("\t") }[0..-2]

puts "Your mac address is : #{$MAC_ADDR}"
at_exit do
	puts "Your mac address before exit is : #{Ip.mac $INTERFACE}"
	Ip.mac $INTERFACE, $MAC_ADDR
	puts "Your mac address after exit is : #{Ip.mac $INTERFACE}"
end

position = 0
menu = Menu.new menu

menu.draw_menu(position)
while ch = menu.get_char
	case ch
	when "k", :up
		position -= 1
	when "j", :down
		position += 1
	when "\n", " "
		puts menu.menu[position]
		mac = menu.menu[position].split("\t")[0]
		Ip.mac $INTERFACE, mac
		`ping #{router} -i 0`
	when 'x'
		exit
	end

	position = menu.size - 1 if position < 0
	position = 0 if position >= menu.size
	menu.clear
	menu.draw_menu(position)
end
