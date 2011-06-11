require 'rubygems'
require 'socket'
require 'yaml'
require 'indextank'

config = YAML::load(File.open('config.yaml'))
chan = config['channel']
api = IndexTank::Client.new config['api_url']
idxname = chan.sub '#', '_'
nick = 'indextank' + idxname
indexes = api.indexes 
index = api.indexes idxname
if not index.exists?
  index.add 
  while not index.running?
      sleep 0.5
      printf "waiting for index %s to be ready...\n", idxname
  end
end
printf "Ready.\n"


while true
	s = TCPSocket.open(config['server'], config['port'])
	print("addr: ", s.addr.join(":"), "\n")
	print("peer: ", s.peeraddr.join(":"), "\n")
	s.puts "USER " + nick + " 0 * " + config['name']
	s.puts "NICK #{nick}"
	s.puts "JOIN #{chan}"

	until s.eof? do
		msg = s.gets
		if msg.match /^PING/
		    s.puts msg.gsub 'PING', 'PONG'
		else
		    puts msg
        parts = msg.split('PRIVMSG')
        if parts.size > 1
          user = parts[0].split('!')[0][1..-1]
          text = parts[1][2 + chan.size..-1]
          printf "user: %s, text %s", user, text
          ts = Time.now.to_i
          docid = user + ':' + ts.to_s
          index.document(docid).add({ :user => user, :text => user + ' ' + text, :timestamp => ts})
        end
		    STDOUT.flush
		end
	end
 sleep 2
end
