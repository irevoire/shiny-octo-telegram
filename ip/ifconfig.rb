class Ifconfig

	# -> true if iproute2 is installed
	def self.available?
		!`which ifconfig`.strip.empty?
	end

	# interface -> ip addr
	def self.ip int
		ip_link = `ifconfig #{int}`
		return ip_link[/inet (.+?) /m, 1]
	end

	# interface -> mac addr
	def self.mac int, mac = nil
		if mac == nil
			ip_link = `ifconfig #{int}`
			return ip_link[/ether (.+?) /m, 1]
		end
		`ifconfig #{int} ether #{mac}`
	end

	# interface -> router
	def self.router int
		ip_link = `route -n get default`
		return ip_link[/gateway: (.+?) /m, 1]
	end
end
