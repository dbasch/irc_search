require 'rubygems'
require 'socket'
require 'yaml'
require 'indextank'

DELIM = ' PRIVMSG'
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

docid = 0
#dummy document that keeps the next id as a variable
res = index.search("nextid:nextid", :fetch_variables => true)
init = true
if res['matches'] != 0
  docid = res['results'][0]['variable_0']
  init = false
end

printf "next docid is %d\n", docid
   

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
        parts = msg.split DELIM
        if parts.size > 1
          user = parts[0].split('!')[0][1..-1]
          rest = parts[1..-1].join DELIM
          text = rest[2 + chan.size..-1]
          printf "docid: %d, user: %s, text %s", docid, user, text
          ts = Time.now.to_i
          if init
            index.document("nextid").add({:nextid => :nextid})
            init = false
          end
          index.document(docid.to_s).add({ :user => user, :text => user + ' ' + text, :timestamp => ts, :matchall => :all}, :variables => {1 => docid})
          docid += 1
          index.document(:nextid).update_variables(0 => docid)
        end
		    STDOUT.flush
		end
	end
 sleep 2
end
