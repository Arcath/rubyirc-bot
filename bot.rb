# /usr/bin/env ruby
require 'socket'
require 'timeout'
require 'db.rb'

class Bot
	def initialize(nick, host, name, admin, moderator)
		@nick=nick
		@host=host
		@name=name
		@admin=admin
		@moderator=moderator
		@nickmsg=''
		@lastlink=''
		@nicks={}
		@query=[]
#		@count=100
#		@mode=1
		puts "#{@nick} initialised"
	end
	def connect(host)
		@conn=TCPsocket.new(host,6667)
		puts "Connecting to #{host}"
		puts "USER String is \"USER #{@nick} #{@host} bla: #{@name}\""
		place("USER " + @nick + " " + @host + " bla :" + @name)
		place("NICK " + @nick)
		msg = @conn.recv(512)
		while msg !~ /^:.* 001.*/
			puts msg
			if msg =~ /Nickname is already in use/
				@nick = @nick + '_'
				place("NICK #{@nick}")
			end
			msg = @conn.recv(512)
		end
		puts "Connected as #{@nick}!"
	end
	def disconnect
		@conn.close
	end
	def recv
		@conn.recv(512)
	end
	def place(s)
		strx=s.gsub(/\n/, "")
		strx=strx.gsub(/\r/, "")
		@conn.send strx + "\n", 0
	end
	def identify(pass)
		self.place("PRIVMSG NickServ :IDENTIFY #{pass}")
		msg=self.recv
		puts msg
		while msg !~ /901/
			msg=self.recv
			puts msg
		end
		puts "Identified as #{@nick}."
	end
	def join(chan)
		self.place("JOIN #{chan}")
		puts "Joined #{chan}"
	end
	def notice(msg, chan)
		self.place("NOTICE #{chan} :#{msg}")
	end
	def parse
		s=self.recv
		s=s.split("\:",3)
		if s[1] =~ /!/ then
			nick=s[1].split("!")[0]
		end
		if s[1] =~ /\ / then
			chan=s[1].split("\ ")[2]
		end
		if s[2] != nil then
			puts s[2]
			snew=s[2].downcase
		end
		if s[3] != nil then
			puts s[3]
			snew=snew+s[3].downcase
		end
		if chan == @nick then
			chan1 =chan
			chan =nick
		end
		if s[0] =~ /PING/ then
			self.place("PONG #{@host} #{s[1]}")
		end
		if snew =~ /^!help/ then
			if @admin.include?(nick) or @moderator.include?(nick)
				if @admin.include?(nick) then
					msg="an administrator"
				else
					msg="a moderator"
				end
				self.notice("You are #{msg}, To add to the database \"!tell <topic>, <fact>\", to remove \"!forget <topic>, <fact>\"",chan)
			else
				self.notice("To query the database \"!about <topic>\"",chan)
			end
		end
		if snew =~ /^!time/ then
			t=Time.now
			self.notice("The Time is: #{t}",chan)
		end
		if snew =~ /^!kill/ then
			if @admin.include?(nick) then
				self.disconnect
			end
		end
		if snew =~ /^!tell/ then
			if @admin.include?(nick) or @moderator.include?(nick) then
				begin
					input=snew.split("!tell ")
					add=input[1].split(", ")
					item=add[0]
					fact=add[1]
					check=item.split(" ")
					fname=""
					check.each do |stitch|
						fname=fname + stitch
					end
					if File.exists?("db/" + fname + ".txt") then
						write=File.open("db/" + fname + ".txt",'a+')
						write.puts fact
						write.close
					else
						write=File.open("db/" +fname + ".txt",'w+')
						write.puts fact
						write.close
					end
					self.notice("I'll Remember That!",chan)
				rescue TypeError
					self.notice("Error",chan)
				end
			end
		end
		if snew =~ /^!about/ then
			input=snew.split("!about ")
			item=input[1]
			if item != nil then
				check=item.split(" ")
				fname=""
				check.each do |stitch|
					fname=fname + stitch
				end
				if File.exist?("db/" + fname + ".txt") then
					self.notice("#{item}:",chan)
					file=File.new("db/" + fname + ".txt")
					begin
						while (line = file.readline)
							line.chomp
							self.notice(line,chan)
						end
					rescue EOFError
						file.close
					end
				else
					self.notice("I dont know anything about #{item}",chan)
				end
			end
		end
#		if @count!=0 then
#			@count=@count-1
#			if @mode==1 then
#				sleep 0.2
#				place("PRIVMSG #{chan} :#{snew}")
#			elsif @mode==2 then
#				if nick == "FallingBullets" then
#					place("PRIVMSG #{chan} :#{snew}")
#				end	
#			end
#		else
#			@count=10
#			@mode=2
#		end
	end
end

bot=Bot.new('Verbend', 'arcath.net', 'Verbend', ["Arcath"], ["Corker"])
bot.connect('heinlein.freenode.net')
bot.identify('dyton')
bot.join('#whitefall')
while 1
	bot.parse
end
