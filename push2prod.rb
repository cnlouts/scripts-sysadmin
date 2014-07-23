#!/usr/bin/env ruby
# TODO configure iptables to block everything but www,ssh and  mysql from staging
# gem install net-ssh

require 'net/ssh'
require 'securerandom'

@password  = SecureRandom.urlsafe_base64
@password2 = SecureRandom.urlsafe_base64
@host = "162.243.120.75"
@user = "root"


def do_createUser(ssh, newClientSite)
  pwd = @password.crypt("$5$a1")
  puts @password
  user = newClientSite.chop
  ssh.exec!("/usr/sbin/useradd -G clients -b /home/clients -m -p '#{ pwd }' #{ user }") #TEST PWD loging in, remove ' 
  ssh.exec!("/bin/chmod 0755 /home/clients/#{ user }")
end

def do_mysqlSetup(ssh, newClientSite)
  dbname = newClientSite
  system("mysqldump #{ newClientSite } > /tmp/#{ newClientSite }.sql")
  client = Mysql2::Client.new(:host => "x.x.x.x", :username => "script", :password => "***")
      client.query("CREATE DATABASE #{ dbname }")
      client.query("CREATE USER #{ dbname }@localhost;")
      client.query("SET PASSWORD FOR #{ dbname }@localhost= PASSWORD('#{ @password2 }');")
      client.query("GRANT SELECT,INSERT,UPDATE,DELETE ON #{ dbname }.* TO #{ dbname }@localhost")
      client.query("FLUSH PRIVILEGES;")
      client.close
end

def do_copySite
end


#Here we going to clear the screen and pop menu.
system 'clear'
print "move2production. for support cfernandez@hispagatos.org\n"
print "====================================================================================\n"
print "Enter the NAME of the site to migrate, example: client1 or client2: "
  newClientSite = gets.chomp.downcase
puts "" # print an empty line
print "Enter Email address: "
  email = gets.chomp.downcase


  
Net::SSH.start("#{ @host }", "#{ @user }") do |ssh|  
  do_createUser(ssh, newClientSite)
  do_mysqlSetup(ssh, newClientSite)
end
