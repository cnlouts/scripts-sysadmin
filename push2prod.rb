#!/usr/bin/env ruby
# TODO email user/password to client
# gem install net-ssh

require 'net/ssh'
require 'net/scp'
require 'securerandom'

@password  = SecureRandom.urlsafe_base64
@password2 = SecureRandom.urlsafe_base64
@host = "162.243.120.75"
@user = "root"


def do_createUser(ssh, newClientSite)
  pwd = @password.crypt("$5$a1")
  puts @password
  user = newClientSite.chop
  ssh.exec!("/usr/sbin/useradd -G clients -b /home/clients -m -p '#{ pwd }' #{ user }") 
  ssh.exec!("/bin/chmod 0755 /home/clients/#{ user }")
end


def do_copyMysqlDump(scp, newClientSite)
  dbname = newClientSite.chop
  system("mysqldump #{ newClientSite } > /tmp/#{ dbname }.sql")
  scp.upload! "/tmp/#{ dbname }.sql", "/home/clients/#{ dbname }/#{ dbname }.sql"
end

def do_copySite(scp, newClientSite)
  client = newClientSite.chop
  system("tar -jcvf /tmp/#{ client }.tar.bzip2 /home/developers/#{ client }/#{ newClientSite }")
  scp.upload! "/tmp/#{ client }.tar.bzip2", "/home/clients/#{ client }/"
end


def do_mysqlSetup(ssh, newClientSite)
  dbname = newClientSite.chop
  client = newClientSite.chop
  client = Mysql2::Client.new(:host => "xx.xx.xx.xx", :username => "script", :password => "xxxxxxx")
      client.query("CREATE DATABASE #{ dbname }")
      client.query("CREATE USER #{ client }@localhost;")
      client.query("SET PASSWORD FOR #{ client }@localhost= PASSWORD('#{ @password2 }');")
      client.query("GRANT SELECT,INSERT,UPDATE,DELETE ON #{ dbname }.* TO #{ client }@localhost")
      client.query("FLUSH PRIVILEGES;")
      client.close
  ssh.exec!("mysql #{ dbname } < /home/clients/#{ dbname }/#{ dbname }.sql")
end


def do_wpSetup(ssh, newClientSite)
  client = newClientSite.chop
  wpdir = "/home/clients/#{ client }/www"
  ssh.exec!("/usr/bin/tar -jxvf /home/clients/#{ client }/#{ client }.tar.bzip2 -C /home/clients/#{ client }/") 
  ssh.exec!("/usr/bin/mv /home/clients/#{ client }/#{ newClientSite } /home/clients/#{ client }/www")
  ssh.exec!("sed -i s/#{ newClientSite }/#{ client }/g #{ wpdir }/wp-config.php")
  ssh.exec!("CHANGE PASSWORD HERE")
end

#Here we going to clear the screen and pop menu.
system 'clear'
print "move2production. for support cfernandez@hispagatos.org\n"
print "====================================================================================\n"
print "Enter the NAME of the site to migrate, example: client1 or client2: "
  newClientSite = gets.chomp.downcase
print ""
print "Enter DNS name, EXAMPLE: myname.com"
  newDNSname = gets.chomp.downcase
puts "" # print an empty line
print "Enter Email address: "
  email = gets.chomp.downcase


Net::SCP.start("#{ @hosts }", "#{ @user }") do |scp|
  do_copyMysqlDump(scp, newClientSite)
  do_copySite(scp, newClientSite)
end

Net::SSH.start("#{ @host }", "#{ @user }") do |ssh|  
  do_createUser(ssh, newClientSite)
  do_mysqlSetup(ssh, newClientSite)
  do_wpSetup(ssh, newClientSite)
end
