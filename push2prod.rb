#!/usr/bin/env ruby
# TODO email user/password to client
# gem install net-ssh

require 'net/ssh'
require 'net/scp'
require 'securerandom'
require 'fileutils'
require 'io/console'
require 'mail'
require 'mysql2'

@password  = SecureRandom.urlsafe_base64
@password2 = SecureRandom.urlsafe_base64
@host = "162.xx.xx.xx"
@user = "root"


def do_createUser(ssh, newClientSite)
  pwd = @password.crypt("$5$a1")
  puts @password
  user = newClientSite.chop
  ssh.exec!("/usr/sbin/useradd -G clients -b /home/clients -m -p '#{ pwd }' #{ user }") 
  ssh.exec!("/bin/chmod 0755 /home/clients/#{ user }")
end


def do_copyMysqlDump(scp, newClientSite, newDNSname)
  dbname = newClientSite.chop
  cmd = 'sed -i "s/preview.logoworks.com\/' + "#{ newClientSite }" + "/#{ newDNSname }/g\" "+ "/tmp/#{ dbname }.sql"
  system("mysqldump #{ newClientSite } > /tmp/#{ dbname }.sql")
  system(cmd)
  scp.upload!("/tmp/#{ dbname }.sql", "/tmp/#{ dbname }.sql")
end

def do_copySite(scp, newClientSite, developer)
  client = newClientSite.chop
  FileUtils.chdir("/home/developers/#{ developer }/#{ client }/")
  system("tar -jcvf /tmp/#{ client }.tar.bzip2  #{ newClientSite }")
  scp.upload!("/tmp/#{ client }.tar.bzip2", "/tmp/")
end


def do_mysqlSetup(ssh, newClientSite)
  dbname = newClientSite.chop
  user = newClientSite.chop
  client = Mysql2::Client.new(:host => "162.xx.xx.xx", :username => "script", :password => "*******")
      client.query("CREATE DATABASE #{ dbname }")
      client.query("CREATE USER #{ user }@localhost;")
      client.query("SET PASSWORD FOR #{ user }@localhost= PASSWORD('#{ @password2 }');")
      client.query("GRANT SELECT,INSERT,UPDATE,DELETE ON #{ dbname }.* TO #{ user }@localhost") #removed CREATE testing
      client.query("FLUSH PRIVILEGES;")
      client.close
  ssh.exec!("mysql #{ dbname } < /tmp/#{ dbname }.sql")
end


def do_wpSetup(ssh, newClientSite)
  client = newClientSite.chop
  pw = "#{ @password2 }"
  wp_path = "/home/clients/#{ client }/www"
  cmd = 'sed -i "25s/^.*$/define\(\'DB_PASSWORD\'\, \'' + "#{ pw }" + '\'\)\;/g" ' + "#{ wp_path }/wp-config.php"
  wpdir = "/home/clients/#{ client }/www"
  ssh.exec!("/bin/tar -jxvf /tmp/#{ client }.tar.bzip2 -C /home/clients/#{ client }/") 
  ssh.exec!("/bin/mv /home/clients/#{ client }/#{ newClientSite } /home/clients/#{ client }/www")
  ssh.exec!("sed -i s/#{ newClientSite }/#{ client }/g #{ wpdir }/wp-config.php")
  ssh.exec!(cmd)
  ssh.exec!("chgrp -R #{ client }:www-data #{ wp_path }")

end


def do_nginx(ssh, newClientSite, newDNSname)
  client = newClientSite.chop
  ssh.exec!("sed s/change/#{ client }/g /etc/nginx/sites-template/template > /etc/nginx/sites-available/#{ newDNSname }")
  ssh.exec!("sed -i s/domain_name/#{ newDNSname }/g /etc/nginx/sites-available/#{ newDNSname }")
  ssh.exec!("ln -s /etc/nginx/sites-available/#{ newDNSname } /etc/nginx/sites-enabled/#{ newDNSname }")
  ssh.exec!("service nginx reload")
end



def do_mail_client(newClientSite,pw,email,newDNSname)
  uname = newClientSite.chop
  mail = Mail.new do
    from    'admin@logoworks.com'
    to      "#{ email }"
    subject 'This is your new account info'
    #body    File.read('email_body.txt')
    body    "you username is: #{uname}, your password is: #{pw} site will be in http://#{ newDNSname }/"
  end
  mail.delivery_method :sendmail
  mail.deliver!
end



#Here we going to clear the screen and pop menu.
system 'clear'
print "move2production. for support cfernandez@hispagatos.org\n"
print "====================================================================================\n"
print "Enter the NAME of the site to migrate, example: client1 or client2: "
  newClientSite = gets.chomp.downcase
puts ""
print "Enter DNS name, EXAMPLE (myname.com): "
  newDNSname = gets.chomp.downcase
puts ""
print "Enter Email address: "
  email = gets.chomp.downcase
puts ""
print "Enter 'Developer' username(firstname-lastname): "
  developer = gets.chomp.downcase

Net::SCP.start("#{ @host }", "#{ @user }") do |scp|
  do_copyMysqlDump(scp, newClientSite, newDNSname)
  do_copySite(scp, newClientSite, developer)
end

Net::SSH.start("#{ @host }", "#{ @user }") do |ssh|  
  do_createUser(ssh, newClientSite)
  do_mysqlSetup(ssh, newClientSite)
  do_wpSetup(ssh, newClientSite)
  do_nginx(ssh, newClientSite, newDNSname)
end

do_mail_client(newClientSite,@password,email,newDNSname)
