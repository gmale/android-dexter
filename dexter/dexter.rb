#!/usr/bin/env ruby

require 'open3'

APK_FILE = ARGV[0]
TAB_WIDTH = 4
REGEX = Regexp.compile(/(\ +)([^<:]+): (\d+)/)
DEX_COUNT_JAR="../dex-method-counts/build/jar/dex-method-counts.jar"

cmd = "../dex-method-counts/dex-method-counts #{APK_FILE}"
# cmd = "sed -n '104,111p' output.txt"
$package_info = []
$method_count_data = Hash.new
$previous_tab_count = 0

# Checks for the required files, as a convenience
#
def init_dependencies()
	if File.exist?(DEX_COUNT_JAR)
		puts "found required files"
	else
		puts "initializing required files..."
		# quietly build the JAR
		Open3.popen3('cd ../dex-method-counts;ant jar')
	end
end

# Parses an individual line of output from the dex-method-count command
# Params:
# +line+:: the line of output to parse
def parse_dex_info(line)
	_, white_space, key, method_count = REGEX.match(line).to_a.flatten

	# only if we've successfully parsed this line
	unless white_space.nil? || white_space.size == 0
		tab_count = white_space.size / TAB_WIDTH
		tab_diff = $previous_tab_count - tab_count + 1
		tab_diff.times do
			$package_info.pop
		end

		$package_info.push key

		package_name = $package_info.join(".")
		$method_count_data[package_name] = method_count

		$previous_tab_count = tab_count
	end
end

def print_result()
	if ARGV[1] == "--alpha"
		$method_count_data.keys.sort.each do |key|
			puts "#{key}: #{$method_count_data[key]}"
		end
	else
		$method_count_data.sort_by{ |k,v| v.to_i }.reverse.each do |key, value|
			puts "#{value}\t#{key}"
		end
	end
		
end

init_dependencies

Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
	stdout.each_line do |line|
  		parse_dex_info line
	end
	print_result
end
