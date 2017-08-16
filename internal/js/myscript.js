let timer;
let on_pause = false;

function addZero (time) {
	return time < 10 ? "0"+time : time.toString();
}

function startTimer (distance, is_on_pause) {
	on_pause = is_on_pause;
	timer = setInterval (function () {
		let time_string;
		if (distance > 0 && !on_pause) {
			// var seconds = sec_left % 60; // верно
			// var minutes = ((sec_left - seconds)/60) % 60;
			// var hours = (sec_left - seconds - 60*minutes)/3600;
			// Time calculations for days, hours, minutes and seconds
		    var hours = Math.floor((distance % (1 * 60 * 60 * 24)) / (1 * 60 * 60));
		    var minutes = Math.floor((distance % (1 * 60 * 60)) / (1 * 60));
		    var seconds = Math.floor((distance % (1 * 60)) / 1);
		    let sec_left = hours*3600+minutes*60+seconds;
			hours = addZero (hours);
			minutes = addZero (minutes);
			seconds = addZero (seconds);
			distance-=1;
			time_string = `${hours}:${minutes}:${seconds}`;
		}
		else if (!on_pause) {
			time_string = "Время вышло!";
		}
		else
			time_string = document.getElementById('timer').innerHTML;
		document.getElementById('timer').innerHTML = time_string;
	}, 1000);
}

function playYoutube() {
	on_pause = false;
	let xhttp = new XMLHttpRequest();
	xhttp.open("POST", "controls/playYoutube", true);
	xhttp.send();
}

function pauseYoutube() {
	on_pause = true;
	let xhttp = new XMLHttpRequest();
	xhttp.open("POST", "controls/pauseYoutube", true);
	xhttp.send();
}

function addTarget() {
	// Спрашиваем ip хоста
	let host_ip = prompt('Введите IP хоста:');
	if (host_ip != null && isIpCorrect(host_ip)) {
		let xhttp = new XMLHttpRequest();
		xhttp.open("POST", `/add_host?host_ip=${host_ip}`, false);
		xhttp.send();
		window.location.reload(true); // загрузка страницы с сервера
	}
	else if (host_ip != null)
		alert ("Некорректный IP!");
}

function isIpCorrect(host_ip) {
	let ip_parts = host_ip.split('.');
	if (ip_parts.length != 4)
		return false;
	for (let i = 0; i < 4; i++) {
		if (parseInt(ip_parts[i]) === NaN)
			return false;
		else if (parseInt(ip_parts[i]) < 0 || parseInt(ip_parts[i]) > 255)
			return false;
	}
	return true;
}

function deleteHost(ip) {
	// запросим подтверждение
	if (window.confirm(`Удалить хост ${ip}?`)) {
		// нужно послать запрос с параметром host_ip
		let xhttp = new XMLHttpRequest();
		xhttp.open("POST", `/delete_host?host_ip=${ip}`, false); // синхронный запрос
		xhttp.send();
		window.location.reload(true); // загрузка страницы с сервера
	}
}

function addRule(ip) {
	// показываем окно 
	let service = prompt('Введите id сайта:');
	if (service != null && (getListOfSites().indexOf(service) != -1)) {
		let xhttp = new XMLHttpRequest();
		xhttp.open("POST", `/add_rule?host_ip=${ip}&service=${service}`, false);
		xhttp.send();
		window.location.reload(true); // загрузка страницы с сервера
	}
	else
		alert ("Некорректный сервис!");
}

function unblockService(ip,srv) {
	let xhttp = new XMLHttpRequest();
	xhttp.open("POST", `/unblock_service?host_ip=${ip}&service=${srv}`, false);
	xhttp.send();
	window.location.reload(true); // загрузка страницы с сервера
}
function blockService(ip,srv) {
	let xhttp = new XMLHttpRequest();
	xhttp.open("POST", `/block_service?host_ip=${ip}&service=${srv}`, false);
	xhttp.send();
	window.location.reload(true); // загрузка страницы с сервера
}