require_relative 'firewall_model'

def table_head(ip)
	s =  "\n"
	s << "<div class=\"row\">"
	s << "<h4>\n"
	s << " Хост #{ip}:\n"
	s << "	<button 	type=\"button\"\n"
	s << "				class=\"btn btn-link \"\n"
	s << "				onclick=\"addRule('#{ip}')\">\n"
	s << "				Добавить правило"
	s << "	</button>\n"
	s << "<button type=\"button\" class=\"btn btn-link\" onclick=\"deleteHost('#{ip}')\">Удалить хост</button>\n"
	s << "\n"
	s << "</h4>\n"
	s
end

def htmlfy(ip)
	ip.gsub '.','-'
end

def service_name_to_img(service)
	case service
	when "youtube"
	  '<img src="/img/youtube.png" alt="YouTube" class="menu-thumb">'
	when "shararam"
	  '<img src="/img/shararam.jpg" alt="Шарарам" class="menu-thumb">'
	else
	  'Сервис'
	end
end

def service_to_name(service)
	case service
	when "youtube"
	  'YouTube'
	when "shararam"
	  'Шарарам'
	else
	  service
	end
end

def table(host)
  s = "\n"
  s << "<div class=\"col-sm-8\">"
  s << table_head(host.ip)
    s << "<table class=\"table table-condensed table-hover\">\n"
    s << "	<tbody>\n"
    host.services.each do |srv|
	    s << "	<tr>\n"
	    s << "		<td class=\"menu-item\">\n"
	    s << "			#{service_name_to_img(srv.name)}\n"
	    s << "		</td>\n"
	    s << "		<td class=\"menu-item-name\">\n"
	    s << "			#{service_to_name(srv.name)}\n"
	    s << "		</td>\n"
	    s << "		<td class=\"#{srv.is_filtered ? "time-block" : "time-unblock"} menu-item\">\n"
	    s << "			#{srv.is_filtered ? "Заблокирован" : "Доступен"}\n"
	    s << "		</td>\n"
	    s << "		<td class=\"menu-item\">\n"
	    if (srv.is_filtered)
	    	s << "			<button class=\"btn btn-success center\" onclick=\"unblockService(\'#{host.ip}\',\'#{srv.name}\')\">\n"
	    	s << "				Разблокировать"
	    	s << "			</button>\n"
	    else
	    	s << "			<button class=\"btn btn-danger center\" onclick=\"blockService(\'#{host.ip}\',\'#{srv.name}\')\">\n"
	    	s << "				Заблокировать"
	    	s << "			</button>\n"
	    end
	    s << "		</td>\n"
	    s << "	</tr>\n"
    end
    # s << "	<tr><td>\n"
    # s << "		<button type=\"button\" class=\"btn btn-primary\" onclick=\"addRule(#{host.ip})\">Добавить правило</button>\n"
    # s << "	</td></tr>\n"
    s << "	</tbody>\n"
    s << "</table>\n"
    s << "</div>"
    s << "</div>"
  # end
  s
end

def empty_firewall
	"<p><h4> Файервол пуст. Добавьте цели! </h4></p>"
end

def select_options
	s = "<form>"
	s << "<label class=\"radio-inline\"><input type=\"radio\" name=\"optradio\" id=\"youtube\">#{service_name_to_img('youtube')}</label>\n"
	s << "<label class=\"radio-inline\"><input type=\"radio\" name=\"optradio\" id=\"shararam\">#{service_name_to_img('shararam')}</label>\n"
	s << "</form>"
	s
end