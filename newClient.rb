#!/usr/bin/env ruby
# script by Chris Fernandez cfernandez@hispagatos.org
# templates for vhosts on /etc/nginx/templates
# with time get rid of the system/sudo calls

require 'securerandom'
require 'fileutils'
require 'mysql2'

@password  = SecureRandom.urlsafe_base64
@password2 = SecureRandom.urlsafe_base64

def directory_exists?(directory)
  File.directory?(directory)
end


#def sudome(command)
#  if ENV["USER"] != "root"
#    system("sudo #{ command }")
#  end
#end


def do_create_directory(devName, clientName)
  home    = "/home/developers/#{ devName }"
  dirpath = "#{ home }/#{ clientName }"
  puts dirpath

  unless directory_exists?(dirpath)
    puts "Creating directory for #{ clientName }"
    Dir.mkdir("#{ dirpath }")
    system("sudo /bin/chown -R #{ devName }:www-data #{ dirpath }")
  else
    puts "Directory  #{ clientName } already exits"
    abort("Directory  #{ clientName } already exits") 
  end
  
end

def do_mysql(devName, clientName)
  client = Mysql2::Client.new(:host => "localhost", :username => "script", :password => "********")
  cmd = "INSERT INTO users (name, client) VALUES (\"#{ devName }\", \"#{ clientName }\");"
  client.query("use developers;")
  client.query(cmd)
  (1..2).each do |i|
    dbname = clientName + "#{ i }"
    #add a test if db exist
      client.query("CREATE DATABASE #{ dbname }")
      client.query("CREATE USER #{ dbname }@localhost;")
      client.query("SET PASSWORD FOR #{ dbname }@localhost= PASSWORD('#{ @password }');")
      client.query("GRANT SELECT,CREATE,INSERT,UPDATE,DELETE ON #{ dbname }.* TO #{ dbname }@localhost")
      client.query("FLUSH PRIVILEGES;")
  end
end

def do_wordpress(devName, clientName)
  home    = "/home/developers/#{ devName }"
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
      system("sed -i 's/put your unique phrase here/#{ @password2 }/g' #{ wpdir }/wp-config.php")
      cmd="echo \"define(\'FS_METHOD\', \'direct\');\" >> #{ wpdir }/wp-config.php"
      system(cmd)
      FileUtils.chmod_R 0775, "#{ wpdir }/wp-content"
    else
      puts "Directory  #{ client } already exits"
    end
  end
  system("sudo /bin/chown -R #{ devName }:www-data #{ dirpath }")  
end


def do_symlink(devName, clientName)
  home    = "/home/developers/#{ devName }"
  dirpath = "#{ home }/#{ clientName }"
  (1..2).each do |i|
    client = "#{ clientName }" + "#{ i }"
    wpdir = "#{ dirpath }/#{ client }"
    system("sudo /bin/ln -s #{ wpdir } /usr/share/nginx/html/#{ client }")
    system("service nginx reload")

    puts "*********************************************************************************"
    puts ""
    puts "Now visit http://preview.logoworks.com/#{ client } to finish the instalation ASAP"
    puts ""
    puts "*********************************************************************************"
  end
  system("sudo /bin/chown -R #{ devName }:www-data #{ dirpath }")
end


#Here we going to clear the screen and pop menu.
system 'clear'
print "Welcome to the new Client install script.. for support cfernandez@hispagatos.org\n"
print "====================================================================================\n"
print "Enter the Developer name format(firstname-lastname): "
  devName = gets.chomp.downcase
puts ""
print "**Now we going to create the skeleton for development**\n"
print "Enter the CLIENT name of the skeleton: "
  clientName = gets.chomp.downcase

# check if client exist already and exit
if directory_exists?("/home/developers/#{ devName }/#{ clientName }")
  puts "Sorry, #{ clientName } is already in use.  Please choose a different name"
  abort "Sorry, #{ clientName } is already in use.  Please choose a different name"
end


do_create_directory(devName, clientName)
do_wordpress(devName, clientName)
do_mysql(devName, clientName)
do_symlink(devName, clientName)
