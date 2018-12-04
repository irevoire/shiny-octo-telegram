require "curses"
include Curses

if ARGV.size != 1
	puts "Usage: #{__FILE__} interface"
	exit
end

$INTERFACE = ARGV[0]

if Process.uid != 0
	puts "Script need to be run as root"
	exit 
end

# get your ip address
ip_link = `ip addr show dev #{$INTERFACE}`
ip_addr = ip_link[/inet (.+?) brd/m, 1]
$MAC_ADDR = ip_link[/link\/ether (.+?) brd/m, 1]
ip, br = ip_addr.split("/")
base = ip.split(".")[0..2].append("0").join(".")
router = ip.split(".")[0..2].append("1").join(".")

nmap = `nmap -sP #{base}/#{br} | awk '/^Nmap/ {printf $5" "} /^MAC/ {print $3}'`

$menu = nmap.lines.map { |line| line.split(" ").reverse.join("\t") }[0..-2]

puts "Your mac address is : #{$MAC_ADDR}"

at_exit do
	`ip link set #{$INTERFACE} down`
	`ip link set addr #{$MAC_ADDR} dev #{$INTERFACE}`
	`ip link set #{$INTERFACE} up`

	puts "Your mac address is : #{$MAC_ADDR}"
end

init_screen
start_color
noecho

def draw_menu(cmenu, active_index=nil)
	$menu.each_with_index do |text, i|
		cmenu.setpos(i + 1, 1)
		cmenu.attrset(i == active_index ? A_STANDOUT : A_NORMAL)
		cmenu.addstr text
	end
end

def draw_info(cmenu, text)
	cmenu.setpos(3, 10)
	cmenu.attrset(A_NORMAL)
	cmenu.addstr text
end

position = 0

cmenu = Window.new(Curses.lines, Curses.cols, 0, 0)
cmenu.box('|', '-')
draw_menu(cmenu, position)
while ch = cmenu.getch
	case ch
	when Curses::KEY_UP, "k"
		draw_info cmenu, 'move up'
		position -= 1
	when Curses::KEY_DOWN, "j"
		draw_info cmenu, 'move down'
		position += 1
	when "\n", " "
		puts $menu[position]
		mac = $menu[position].split("\t")[0]
		`ip link set #{$INTERFACE} down`
		`ip link set addr #{mac} dev #{$INTERFACE}`
		`ip link set #{$INTERFACE} up`
		`ping #{router} -i 0`
		`ip link set #{$INTERFACE} down`
		`ip link set addr #{$MAC_ADDR} dev #{$INTERFACE}`
		`ip link set #{$INTERFACE} up`
	when 'x'
		exit
	end

	position = $menu.size - 1 if position < 0
	position = 0 if position >= $menu.size
	draw_menu(cmenu, position)
end
