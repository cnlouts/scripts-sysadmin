#!/usr/bin/env ruby
# install "gem install mail"
# script by Chris Fernandez cfernandez@hispagatos.org
require 'io/console'
require 'mail'


def do_create_user(first,last,pw,email)
  pwd = pw.crypt("$5$a1")
  uname = first.to_s + "-" + last.to_s
  result = system("/usr/sbin/useradd -G managers -b /home/managers -m -p '#{ pwd }' #{ uname }")
    if result
      puts "#{ uname } created!"
      system("/bin/chmod 0755 /home/managers/#{ uname }")
      do_mail_dev(uname,pw,email)
    else
      puts "#{ uname } failed!"
    end
end


def do_mail_dev(uname,pw,email)
  mail = Mail.new do
    from    'admin@logoworks.com'
    to      "#{ email }"
    subject 'This is your new account info'
    #body    File.read('email_body.txt')
    body    "you username is: #{uname}, your password is: #{pw}"
  end
  mail.delivery_method :sendmail
  mail.deliver!
end

#Here we going to clear the screen and pop menu.
system 'clear'
print "Welcome to the new Deverloper install script.. for support cfernandez@hispagatos.org\n"
print "====================================================================================\n"
print "**Now we going to configure the username with format firstname-lastname**\n"
print "Enter the FIRST name of the new manager: "
  first = gets.chomp.downcase
print "Enter the LAST name of the new manager: "
  last = gets.chomp.downcase
print "Enter Password: "
  password = STDIN.noecho(&:gets).chomp
puts "" # print an empty line
print "Enter Email address: "
  email = gets.chomp.downcase

do_create_user(first,last,password,email)
