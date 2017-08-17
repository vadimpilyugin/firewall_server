require 'rubygems'
require 'data_mapper' # requires all the gems listed above
require_relative 'sites'
require_relative 'tools'

class Host
	BLOCK_PREFIX="block_"

	include DataMapper::Resource

	# property :id, Serial
	property :ip, String, :key => true
	property :name, String
	property :is_blocked, Boolean, :default => true

	has n, :services

	def tname
		return "host-#{self.ip}"
	end
	def tblock
		return "blk-#{self.ip}"
	end
end

class Service
	include DataMapper::Resource

	property :id, Serial
	property :name, String, :required => true
	property :is_filtered, Boolean, :default => true
end

class Firewall
	include DataMapper::Resource

	property :id, Serial
	has n, :hosts
end

class HostModel
public
	def self.block_service(ip, service)
		host = Host.get(ip)
		# убрать существующие правила
		flush_services_for_host host
		# изменить существующее
		host.services.first(name:service).update(is_filtered:true)
		# применить обратно с изменениями
		restore_services_for_host host
		Printer::debug msg:"Заблокировали #{service} для хоста #{ip}"
	end
	def self.unblock_service(ip, service)
		host = Host.get(ip)
		# убрать существующие правила
		flush_services_for_host host
		# обновить предыдущее
		host.services.first(name:service).update(is_filtered:false)
		# применить обратно с изменениями
		restore_services_for_host host
		Printer::debug msg:"Разблокировали #{service} для хоста #{ip}"
	end
	def self.add_service(ip, service)
		host = Host.get(ip)
		# убрать существующие правила
		flush_services_for_host host
		# добавить новое правило
		host.services.create(name:service)
		# применить обратно с изменениями
		restore_services_for_host host
		Printer::debug msg:"Добавили фильтрацию сервиса #{service} для хоста #{ip}"
	end
	def self.remove_service(ip, service)
		host = Host.get(ip)
		# убрать существующие правила
		flush_services_for_host host
		# удалить правило
		Printer::debug msg:host.services.inspect
		Printer::debug msg:host.services.first(name:service)
		host.services.first(name:service).destroy
		# применить обратно с изменениями
		restore_services_for_host host
		Printer::debug msg:"Удалили сервис #{service} для хоста #{ip}"
	end
	def self.flush_services_for_host(host)
		`iptables -F #{host.tblock}` # очищаем таблицу сервисов
		`iptables -A #{host.tblock} -j RETURN` # добавляем выход
	end
	def self.insert_service_for_host(host,srv)
		`iptables -I #{host.tblock} 1 -j #{Host::BLOCK_PREFIX+srv.name}` if srv.is_filtered
	end
	def self.restore_services_for_host(host)
		host.services.each do |srv|
			# добавляем ссылки на таблицы проверки сервисов
			# добавляем в начало, чтобы отгородить RETURN
			insert_service_for_host host, srv
		end
	end
private
end

class FirewallModel
public
	def initialize(file)
		# очистить записи в iptables
		pristine_state
		# финализовать модели
		DataMapper.finalize
		# подключиться к базе данных
		DataMapper.setup :default, "sqlite3:///#{file}"
		# подогнать схему
		DataMapper.auto_upgrade!
		# Raise on save!
		DataMapper::Model.raise_on_save_failure = true
		# создаем экземпляр файервола
		fwl = Firewall.first_or_create
		Printer::debug msg:fwl.inspect, who:"Объект файервола"
		Printer::assert(expr:Firewall.first != nil, msg:"Запись не создалась")
		# создаем образы сайтов
		SiteModel.create_all
		# загружаем правила для сайтов в iptables
		apply_rules_for_sites
		# создаем таблицу blocklist
		create_blocklist
		# добавляем ссылку из FORWARD
		create_link_from_forward
		# проходимся по сохраненной модели и добавляем записи в iptables
		fwl.hosts.each do |hst|
			# создаем таблицу блокировки для хоста
			create_block_table hst
			# убрать существующие правила и добавить RETURN
			HostModel::flush_services_for_host hst
			# добавляем каждый сервис
			hst.services.each do |srv|
				HostModel::insert_service_for_host hst,srv
			end
			# создаем таблицу проверки ip-адреса
			create_ip_check_table hst
			# добавляем в таблицу хостов запись
			add_record_to_blocklist hst
		end


		Printer::debug msg:"Модели инициализированы!"
	end
	def add_host(ip, name="")
		# получаем объект файервола
		fwl = Firewall.first
		# добавляем к списку хостов новый хост
		host = fwl.hosts.create ip:ip, name:name
		# создаем таблицу блокировки для хоста
		create_block_table host
		# создаем таблицу проверки ip-адреса
		create_ip_check_table host
		# добавляем в таблицу хостов запись
		add_record_to_blocklist host
		Printer::debug msg:"Добавлен хост #{ip}"
	end
	def remove_host(ip)
		# получаем объект файервола
		fwl = Firewall.first
		# получаем хост
		host = fwl.hosts.get(ip)
		# удаляем таблицу блокировок
		delete_block_table host
		# удаляем таблицу проверки адреса
		delete_ip_check_table host
		# очищаем blocklist
		flush_blocklist
		# удаляем хост
		host.services.destroy
		host.destroy
		# восстанавливаем blocklist
		fill_blocklist fwl.hosts
		Printer::debug msg:"Удален хост #{ip}"
	end
	def block_ip(ip)
		# получаем объект файервола
		fwl = Firewall.first 
		# получаем хост
		host = fwl.hosts.get(ip)
		# меняем состояние block на true
		host.update is_blocked:true
		# добавляем в список хостов первой строкой
		add_host_to_blocklist host
		Printer::debug msg:"Включена блокировка хоста #{ip}"
	end
	def unblock_ip(ip)
		# получаем объект файервола
		fwl = Firewall.first 
		# получаем хост
		host = fwl.hosts.get(ip)
		# очищаем список хостов
		flush_blocklist
		# меняем состояние block на true
		host.update is_blocked:true
		# заполняем обратно
		fill_blocklist fwl.hosts
		Printer::debug msg:"Выключена блокировка хоста #{ip}"
	end
	def clear_all
		pristine_state
		SiteModel.drop
		Service.destroy
		Host.destroy
		Firewall.destroy
		Printer::debug msg:"Правила очищены"
	end
	def rename_host(ip,new_name)
		# получаем объект файервола
		fwl = Firewall.first 
		# получаем хост
		host = fwl.hosts.get(ip)
		# ставим новое имя
		host.update(name:new_name)
	end
	def turn_off_firewall
		remove_link_from_forward
	end
	def get_hosts
		fwl = Firewall.first
		if fwl.nil?
			return nil
		else
			return fwl.hosts
		end
	end
	def get_ip_list
		fwl = Firewall.first
		if fwl.nil?
			return nil
		else
			res = []
			fwl.hosts.each {|hst| res << hst.ip }
			return res
		end
	end

	def save(fn)
		`iptables-save >#{fn}`
	end
	def load(fn)
		`iptables-restore <#{fn}`
	end
	def pristine_state
		`iptables -F` # удалить все правила
		`iptables -X` # удалить все цепочки
		`iptables -P FORWARD ACCEPT` # установить дефолтную политику ACCEPT
	end
private
	# создаем block-таблицу
	def create_block_table(host)
		`iptables -N #{host.tblock}`
	end
	# создаем таблицу для проверки ip
	def create_ip_check_table(host)
		`iptables -N #{host.tname}` 
		`iptables -A #{host.tname} ! -s #{host.ip} ! -d #{host.ip} -j RETURN` # возврат, если пакет не этого юзера
		`iptables -A #{host.tname} -j #{host.tblock}` # перенаправляем на проверку сервисов
		`iptables -A #{host.tname} -j RETURN`
	end
	def add_record_to_blocklist(host)
		`iptables -I blocklist 1 -j #{host.tname}`
	end
	def flush_blocklist
		`iptables -F blocklist`
		`iptables -A blocklist -j RETURN` # возврат по окончании
	end
	def fill_blocklist(hosts)
		hosts.each do |hst|
			`iptables -I blocklist 1 -j #{hst.tname}` if hst.is_blocked # для каждого ip своя цепочка
		end
	end
	def delete_block_table(host)
		`iptables -F #{host.tblock}`
		`iptables -X #{host.tblock}`
	end
	def delete_ip_check_table(host)
		`iptables -F #{host.tname}`
		`iptables -X #{host.tname}`
	end
	def apply_rules_for_sites
		Site.each do |site|
			Printer::debug who:"Фильтрация сайта",msg:site.name
			tname = Host::BLOCK_PREFIX+site.id
			`iptables -N #{tname}` # создаем таблицу проверки трафика на принадлежность сервису
			site.rules.each { |rule| `iptables -A #{tname} #{rule.rule}`; Printer::debug(who:"Правило", msg:"iptables -A #{tname} #{rule.rule}")} # добавляем правила
			`iptables -A #{tname} -j RETURN` # выходим, если правила не удалось применить
		end
	end
	def create_link_from_forward
		`iptables -A FORWARD -j blocklist`
	end
	def remove_link_from_forward
		`iptables -D FORWARD 1`
	end
	def create_blocklist
		`iptables -N blocklist`
		`iptables -A blocklist -j RETURN` # возврат по окончании
	end
end

class ArpspoofModel
	def self.start(ip_list, router_ip)
		Printer::debug msg:"Запускаем процессы arpspoof..."
		@pid_list = {}
	    ip_list.each {|ip| add_host(ip,router_ip) }
	end
	# вызывать при SIGINT с клавиатуры
	def self.stop_without_kill
		Printer::debug msg:"Завершаем все процессы arpspoof...", params:@pid_list
		@pid_list.each_value do |pid| 
			printf "    [#{pid}]:\t".green
			pr_pid, pr_status = Process.wait2(pid)
			puts "OK! #{pr_status}"
		end
	end
	def self.add_host(ip, router_ip)
		if @pid_list.nil?
			@pid_list = {}
		end
		if !@pid_list.has_key?(ip)
			# создает новый процесс, с той же группой
			@pid_list.update(ip => spawn("arpspoof -t #{ip} -r #{router_ip} 2>1 1>/dev/null"))
			Printer::debug msg:"Запустили процесс [#{@pid_list[ip]}] на ip #{ip}"
		end
	end
	def self.delete_host(ip)
		if !@pid_list.nil? && @pid_list.has_key?(ip)
			pid = @pid_list[ip]
			Process.kill 'INT', pid
			Process.wait pid
			Printer::debug msg:"Убили процесс [#{@pid_list[ip]}] на ip #{ip}"
			@pid_list.delete ip
		end
	end
end