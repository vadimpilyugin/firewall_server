require 'rubygems'
require 'data_mapper'

class Host
	BLOCK_PREFIX="block_"

	include DataMapper::Resource

	# property :id, Serial
	property :ip, String, :key => true # ip блокируемого компьютера
	property :name, String # человеко-читабельное имя
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

class Site
	include DataMapper::Resource

	property :id, String, :key => true	# латиницей, в нижнем регистре, уникальное
	property :name, String, :required => true	# читабельное, для человека
	property :url, String
	property :icon, String, :length => 100, :default => "/img/blank.gif"
	property :descr, String, :length => 200, :default => "No description"

	has n, :rules
end

class Rule
	include DataMapper::Resource

	property :id, Serial
	property :rule, String, :length => 100
end