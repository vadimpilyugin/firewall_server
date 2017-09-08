require_relative 'db'

class SiteModel
	def self.create_all
		# Сначала очистить старые данные
		drop
		# YouTube
		s = Site.new(
			id: "youtube",
			name: "YouTube",
			url: "www.youtube.com",
			icon: "/img/youtube.png",
			rules: [
			  Rule.new(rule:'-s 173.194.0.0/16 -p tcp -j DROP'),
			  Rule.new(rule:'-d 173.194.0.0/16 -p tcp -j DROP'),
			  Rule.new(rule:'-s 74.125.0.0/16 -p tcp -j DROP'),
			  Rule.new(rule:'-d 74.125.0.0/16 -p tcp -j DROP'),
			  Rule.new(rule:'-s 5.0.0.0/8 -p tcp -j DROP'),
			  Rule.new(rule:'-d 5.0.0.0/8 -p tcp -j DROP'),
			  Rule.new(rule:'-p udp -m udp --sport 443 -j DROP'),
			  Rule.new(rule:'-p udp -m udp --dport 443 -j DROP'),
			  Rule.new(rule:'-s 74.125.232.0/24 -j DROP'),
			  Rule.new(rule:'-d 74.125.232.0/24 -j DROP')
			]
		)
		s.save
		# Шарарам
		s = Site.new(
			id:"shararam",
			name: "Шарарам",
			url: "www.shararam.ru",
			icon: "/img/shararam.jpg",
			rules: [
			  Rule.new(rule:'-s 109.239.130.3 -p tcp -j DROP'),
			  Rule.new(rule:'-d 109.239.130.3 -p tcp -j DROP'),
			  Rule.new(rule:'-s 109.239.130.2 -p tcp -j DROP'),
			  Rule.new(rule:'-d 109.239.130.2 -p tcp -j DROP')
			]
		)
		s.save
		# ВК
		s = Site.new(
			id:"vk",
			name:"ВКонтакте",
			url:"vk.com",
			icon:"/img/vk.png",
			rules:[
				
			  Rule.new(rule:'-s 87.240.182.0/24 -p tcp -j DROP'),
			  Rule.new(rule:'-d 87.240.182.0/24 -p tcp -j DROP'),

			  Rule.new(rule:'-s 87.240.165.0/24 -p tcp -j DROP'),
			  Rule.new(rule:'-d 87.240.165.0/24 -p tcp -j DROP'),

			  Rule.new(rule:'-s 95.213.0.0/16 -p tcp -j DROP'),
			  Rule.new(rule:'-d 95.213.0.0/16 -p tcp -j DROP'),

			  Rule.new(rule:'-s 93.186.238.0/24 -p tcp -j DROP'),
			  Rule.new(rule:'-d 93.186.238.0/24 -p tcp -j DROP'),
			]
		)
		s.save
		# Все сайты
		s = Site.new(
			id:"all_sites",
			name:"Полная блокировка",
			icon:"/img/firewall.png",
			rules:[
			  Rule.new(rule:'-j DROP')
			]
		)
		s.save
	end
	def self.drop
		Rule.destroy
		Site.destroy
	end
end