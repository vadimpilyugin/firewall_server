require 'sinatra'
require 'yaml'

require_relative 'printer'
require_relative 'firewall_model'
require_relative 'config'

def write_js_config
    File.open('./internal/js/config.rb.js', 'w') do |file|
        s = '
function getListOfSites() {
    return '+Site.all.map {|site| site.id}.to_s+';
}'
        file.write s
    end
end

fwl_model = FirewallModel.new 'base.sqlite3'
write_js_config
if Config['arpspoof']['enable']
    ArpspoofModel.start fwl_model.get_ip_list, Config['arpspoof']['gateway']
end
server_pid = Process.pid
Signal.trap('SIGINT') do 
    puts
    Printer::debug msg:"Откатываем изменения в iptables..."
    fwl_model.pristine_state
    if Config['arpspoof']['enable']
        ArpspoofModel.stop_without_kill
    end
    Printer::debug msg:"Посылаем SIGKILL процессу #{server_pid}"
    Process.kill 'KILL', server_pid
end

configure do
    set :bind, Config['server']['bind_to']
    set :port, Config['server']['port']
    set :public_folder, 'internal'
    disable :traps
end

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [Config['server']['login'], Config['server']['password']]
  end
end

get '/' do
    protected!
    @hosts = fwl_model.get_hosts
	slim :simple
end

post '/add_host' do
    fwl_model.add_host params["host_ip"]
    if Config['arpspoof']['enable']
      ArpspoofModel.add_host params["host_ip"], Config['arpspoof']['gateway']
    end
end
post '/add_rule' do
    HostModel.add_service(params['host_ip'],params['service'])
end
post '/delete_rule' do
    HostModel.remove_service(params['host_ip'],params['service'])
end
post '/delete_host' do
    fwl_model.remove_host params["host_ip"]
    if Config['arpspoof']['enable']
      ArpspoofModel.delete_host params["host_ip"]
    end
end
post '/unblock_service' do
    HostModel.unblock_service params["host_ip"], params["service"]
end
post '/block_service' do
    HostModel.block_service params["host_ip"], params["service"]
end
post '/rename_host' do
    fwl_model.rename_host params["ip"], params["host_name"]
end