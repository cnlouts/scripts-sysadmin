#!/usr/bin/env ruby
# script to remove password and ip from other ruby scripts
# before pushing to public repositories
# in the future add this into arrays to do a better job.

require 'pathname'

@password = "password goes here"
@ip = "ip goes here"
@directory = "domainhere.com"

Dir.glob("#{ @directory }/*.rb").each do |rubyFile|
  singleRubyFile = Pathname.new(rubyFile).relative_path_from( Pathname.new("#{ @directory }") ).to_s
  data = File.read("#{ rubyFile }")
       	puts "Doing #{ rubyFile }"
  newData =  data.gsub("#{ @password }", "********") 
  newData =  newData.gsub("#{ @ip }","xx.xx.xx.xx")
  File.open("scripts-sysadmin/#{ singleRubyFile }", "w") do | newFile |
	  newFile.write(newData)
  end
end
