#!/usr/bin/ruby

require 'date'

puts "strain\tdate\tdate_decimal\tdate_precision\tregion\tcountry\tsource\taccession\tsequence"

inputfile_name = ARGV[0]
file = File.new(inputfile_name, "r")
file.each { |line|

	name, date, rest = "", "", ""
	
	match = line.match(/^(\S+)\t(\d\S+)\t(.+)/)
	if match != nil
	
		name = match[1]
		date = match[2]
		rest = match[3]		
		
		uncertainty = "day"
		fixed_date = date
		
		m = fixed_date.match(/\-XX\-XX/)
		if m != nil
			uncertainty = "year"
		end
		fixed_date = date.gsub(/\-XX\-XX/,"-01-01")
		
		m = fixed_date.match(/\-XX/)
		if m != nil
			uncertainty = "month"
		end
		fixed_date = date.gsub(/\-XX/,"-01")		
		
		m = fixed_date.match(/\-01\-01/)
		if m != nil
			uncertainty = "year"
		end
				
		d = Date.parse(fixed_date)
		decimal = d.year + (d.yday - 1) / 365.to_f

		puts "#{name}\t#{date}\t#{decimal.round(3)}\t#{uncertainty}\t#{rest}"

	end		
	

		
}
file.close


