#!/usr/bin/ruby

filename = ARGV[0]
analysis = ARGV[1]
stem_year = ARGV[2].to_i

# strain name to array of attributes
samples = Hash.new
YEAR = 0
SEQ = 1

infile = File.open(filename, "r")
infile.readlines.each { |line|

	match = line.match(/^(\S+)\t(\d\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)/)
	if match != nil
	
		name = match[1]
		cal_date = match[2]
		date_decimal = match[3]	
		date_precision = match[4]
		country = match[5]
		source = match[6]
		accession = match[7]
		sequence = match[8]
		
		year = date_decimal.to_i
			
		entry = [year, sequence]
		samples[name] = entry
				
	end

}
infile.close

print <<EOF
<?xml version="1.0" standalone="yes"?>
<beast>	
EOF

# taxa
puts "\t<taxa id=\"taxa\">"
samples.each_pair { |name, entry|
	puts "\t\t<taxon id=\"#{name}\"/>"
}
puts "\t</taxa>"

# possible stem taxa
puts "\t<taxa id=\"stems\">"
samples.each_pair { |name, entry|
	if entry[YEAR] == stem_year then
		puts "\t\t<taxon idref=\"#{name}\"/>"
	end
}
puts "\t</taxa>"

# sequences
print "\t<alignment id=\"alignment\" dataType=\"amino acid\">\n"
samples.each_pair { |name, entry|
	print "\t\t<sequence>\n"
	print "\t\t\t<taxon idref=\"#{name}\"/>\n"
	print "\t\t\t#{entry[SEQ]}\n"
	print "\t\t</sequence>\n"
}
print "\t</alignment>\n"

