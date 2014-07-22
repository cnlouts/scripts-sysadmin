#!/usr/bin/env ruby
# script by Chris Fernandez cfernandez@hispagatos.org
# templates for vhosts on /etc/nginx/templates
# -- TODO ---
# configure wordpress

require 'securerandom'
require 'fileutils'
require 'mysql2'

@password = SecureRandom.urlsafe_base64

def directory_exists?(directory)
  File.directory?(directory)
end


def sudome
  if ENV["USER"] != "root"
    exec("sudo #{ENV['_']} #{ARGV.join(' ')}")
  end
end


def do_create_directory(clientName)
  home    = ENV['HOME']
  dirpath = "#{ home }/#{ clientName }"
  puts dirpath

  unless directory_exists?(dirpath)
    puts "Creating directory for #{ clientName }"
    Dir.mkdir("#{ dirpath }")
  else
    puts "Directory  #{ clientName } already exits" 
  end
  
end

def do_mysql(clientName)
  client = Mysql2::Client.new(:host => "localhost", :username => "script", :password => "0pl,9okm")
  (1..2).each do |i|
    dbname = clientName + "#{ i }"
    #add a test if db exist
      #sql = "SET PASSWORD FOR #{ dbname }@localhost= PASSWORD("#{ @password }");"
      client.query("CREATE DATABASE #{ dbname }")
      client.query("CREATE USER #{ dbname }@localhost;")
      client.query("SET PASSWORD FOR #{ dbname }@localhost= PASSWORD('#{ @password }');")
      client.query("GRANT SELECT,INSERT,UPDATE,DELETE ON #{ dbname }.* TO #{ dbname }@localhost")
      client.query("FLUSH PRIVILEGES;")
  
  end
end

def do_wordpress(clientName)
  home    = ENV['HOME']
  dirpath = "#{ home }/#{ clientName }"
  system("wget http://wordpress.org/latest.tar.gz -O /tmp/latest.tar.gz")

  (1..2).each do |i|
    client = "#{ clientName }" + "#{ i }"
    wpdir = "#{ dirpath }/#{ client }"
    

    unless directory_exists?(wpdir)
      system("tar zxvf /tmp/latest.tar.gz -C #{ dirpath }/")
      FileUtils.mv "#{ dirpath }/wordpress", "#{ wpdir }"
      FileUtils.cp "#{ wpdir }/wp-config-sample.php", "#{ wpdir }/wp-config.php"
      system("sed -i s/database_name_here/#{ client }/ #{ wpdir }/wp-config.php")
      system("sed -i s/username_here/#{ client }/ #{ wpdir }/wp-config.php")
      system("sed -i s/password_here/#{ @password}/ #{ wpdir }/wp-config.php")
      #FileUtils.chown_R 'www-data', 'www-data', "#{ wpdir }"
      #text = File.read("#{ wpdir }/wp-config.php")
      #File.write("#{ wpdir }/wp-config.php", text.gsub(/database_name_here/, "#{ client }")
      #File.write("#{ wpdir }/wp-config.php", text.gsub(/username_here/, "#{ client }")
      #File.write("#{ wpdir }/wp-config.php", text.gsub(/password_here/, "#{ @password }")
    else
      puts "Directory  #{ client } already exits"
    end
  end
end


def do_symlink(clientName)
  home    = ENV['HOME']
  dirpath = "#{ home }/#{ clientName }"
  (1..2).each do |i|
    client = "#{ clientName }" + "#{ i }"
    wpdir = "#{ dirpath }/#{ client }"
    command = "ln -s #{ wpdir } /usr/share/nginx/html/#{ client }" 
    unless directory_exists?("/usr/share/nginx/html/#{ client }")
      sudome(command)
    end
  end
end





#Here we going to clear the screen and pop menu.
system 'clear'
print "Welcome to the new Client install script.. for support cfernandez@hispagatos.org\n"
print "====================================================================================\n"
print "**Now we going to create the skeleton for development**\n"
print "Enter the CLIENT name of the skeleton: "
  clientName = gets.chomp.downcase

do_create_directory(clientName)
do_wordpress(clientName)
do_mysql(clientName)
do_symlink(clientName)
