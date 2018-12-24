class Iproute2

	# -> true if iproute2 is installed
	def self.available?
		!`which ip`.strip.empty?
	end

	# interface -> ip addr
	def self.ip int
		ip_link = `ip addr show dev #{int}`
		return ip_link[/inet (.+?)\//m, 1]
	end

	# interface -> mac addr
	def self.mac int, mac = nil
		if mac == nil
			ip_link = `ip link show #{int}`
			return ip_link[/link\/ether (.+?) /m, 1]
		end
		`ip link set #{int} down`
		`ip link set addr #{mac} dev #{int}`
		`ip link set #{int} up`
	end

	# interface -> router
	def self.router int
		ip_link = `ip route`
		return ip_link[/default via (.+?) dev #{int}/m, 1]
	end
end
