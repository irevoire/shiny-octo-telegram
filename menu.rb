class Menu
	attr_accessor :menu

	def initialize menu
		require 'io/console'
		@menu = menu
	end

	def read_char
		STDIN.echo = false
		STDIN.raw!

		input = STDIN.getc.chr
		if input == "\e" then
			input << STDIN.read_nonblock(3) rescue nil
			input << STDIN.read_nonblock(2) rescue nil
		end
	ensure
		STDIN.echo = true
		STDIN.cooked!

		return input
	end

	# oringal case statement from:
	# http://www.alecjacobson.com/weblog/?p=75
	def get_char
		c = read_char

		case c
		when "\e[A"
			return :up
		when "\e[B"
			return :down
		when "\e[C"
			return :right
		when "\e[D"
			return :left
		when "\177"
			return :backspace
		when "\004"
			return :delete
		when "\e[3~"
			return :altdelete
		when "\u0003" # Ctrl C
			exit 0
		when /^.$/ # Only one char
			return c
		else
			STDERR.puts "strange char: #{c.inspect}"
		end
	end

	# take a list of index (0 < int < menu.size)
	# Draw the menu with all indexes highlighted
	def draw *active_index
		@menu.each_with_index do |item, idx|
			print "\e[2K"
			if active_index.include? idx
				print "\e[45;30m"
				print item
				puts "\e[m"
			else
				print item
				puts
			end
		end
	end

	def reset
		print "\e[#{self.size}A"
	end

	def clear
		@menu.size.times {
			print "\e[A\e[K"
		}
	end

	def size
		@menu.size
	end
end

