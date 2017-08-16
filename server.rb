require 'sinatra'
require_relative 'timer'
require_relative 'tools'
require_relative 'firewall_model'
require_relative 'firewall_view'

def fill_config
    File.open('./internal/js/config.rb.js', 'w') do |file|
        s = '
function getListOfSites() {
    return '+Site.all.map {|site| site.id}.to_s+';
}'
        file.write s
    end
end

GATEWAY = '192.168.1.1'
fwl_model = FirewallModel.new 'base.sqlite3'
ArpspoofModel.start fwl_model.get_ip_list, GATEWAY
server_pid = Process.pid
fill_config
Signal.trap('SIGINT') do 
    puts
    Printer::debug msg:"Откатываем изменения в iptables..."
    fwl_model.pristine_state
    ArpspoofModel.stop_without_kill
    Printer::debug msg:"Посылаем SIGKILL процессу #{server_pid}"
    Process.kill 'KILL', server_pid
end


# def set_timer(timer)
# 	s = "<script> startTimer(#{timer.distance}, #{timer.on_pause}); </script>\n"
# 	s
# end

# t = Timer.new 0,0,10
# t.start
# while t.is_time_left?
# 	# printf "#{t.show}\r"
# 	printf t.show

# 	s = gets.chomp
# 	if s == "p"
# 		t.pause
# 	elsif s == "s"
# 		t.start
# 	end
# 	# sleep 1
# end
# t = Timer.new 0,1,0
# t.start

configure do
    set :bind, "192.168.1.96"
    set :port, 4567
    set :public_folder, 'internal'
    disable :traps
end

get '/' do
    @hosts = fwl_model.get_hosts
	slim :simple
end

post '/add_host' do
    fwl_model.add_host params["host_ip"]
    ArpspoofModel.add_host params["host_ip"], GATEWAY
end
post '/add_rule' do
    HostModel.add_service(params['host_ip'],params['service'])
end
post '/delete_host' do
    fwl_model.remove_host params["host_ip"]
    ArpspoofModel.delete_host params["host_ip"]
end
post '/unblock_service' do
    HostModel.unblock_service params["host_ip"], params["service"]
end
post '/block_service' do
    HostModel.block_service params["host_ip"], params["service"]
end

# post '/controls/playYoutube' do
# 	t.start
# 	puts "Started timer: #{t.show}"
# end
# post '/controls/pauseYoutube' do
# 	t.pause
# 	puts "On pause: #{t.show}"
# end

# post '/check_login' do
#     Printer::debug msg:request.accept              # ['text/html', '*/*']
#     Printer::debug msg:request.accept?('text/xml')  # true
#     Printer::debug msg:request.body                # request body sent by the client (see below)
#     Printer::debug msg:request.scheme              # "http"
#     Printer::debug msg:request.script_name         # "/example"
#     Printer::debug msg:request.path_info           # "/foo"
#     Printer::debug msg:request.port                # 80
#     Printer::debug msg:request.request_method      # "GET"
#     Printer::debug msg:request.query_string        # ""
#     Printer::debug msg:request.content_length      # length of request.body
#     Printer::debug msg:request.media_type          # media type of request.body
#     Printer::debug msg:request.host                # "example.com"
#     Printer::debug msg:request.get?                # true (similar methods for other verbs)
#     Printer::debug msg:request.form_data?          # false
#     Printer::debug msg:request["some_param"]       # value of some_param parameter. [] is a shortcut to the params hash.
#     Printer::debug msg:request.referrer            # the referrer of the client or '/'
#     Printer::debug msg:request.user_agent          # user agent (used by :agent condition)
#     Printer::debug msg:request.cookies             # hash of browser cookies
#     Printer::debug msg:request.xhr?                # is this an ajax request?
#     Printer::debug msg:request.url                 # "http://example.com/example/foo"
#     Printer::debug msg:request.path                # "/example/foo"
#     Printer::debug msg:request.ip                  # client IP address
#     Printer::debug msg:request.secure?             # false (would be true over ssl)
#     Printer::debug msg:request.forwarded?          # true (if running behind a reverse proxy)
# 	if params[:email] == "vadimpilyugin@gmail.com" && params[:pass] == "xpb48ask19"
# 		slim :admin_page
# 	else
# 		slim :index
# 	end
# end
# get '/login' do
# 	slim :login
# end