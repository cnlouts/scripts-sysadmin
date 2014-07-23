#!/usr/bin/env ruby
# gem install net-ssh

require 'net/ssh'

@password = SecureRandom.urlsafe_base64




def do_createUser(newClientSite)
  ssh.exec!("hostname")
  ssh.exec!("echo newClientSite")
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


  
Net::SSH.start('host', 'user', :password => "password") do |ssh|  
  do_createUser(newClieintSite)
end
