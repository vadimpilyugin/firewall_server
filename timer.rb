class Timer
	def initialize(hour = 0,min = 0,sec = 0)
		@timer = Time.new 1,1,1,hour,min,sec,0
		@fin = Time.new 1,1,1,0,0,0,0
		@on_pause = true
	end
	attr_reader :on_pause
	def is_time_left?
		@timer > @fin
	end
	def hour
		is_time_left? ? @timer.hour : 0
	end
	def min
		is_time_left? ? @timer.min : 0
	end
	def sec
		is_time_left? ? @timer.sec : 0
	end
	def sec_left
		hour*3600+min*60+sec
	end
	def distance
		@timer - @fin
	end
	def start
		if is_time_left?
			@start = Time.now
			@on_pause = false
		end
	end
	def check
		if is_time_left? && !@on_pause
			now = Time.now
			sec_elapsed = (now - @start).to_i
			@start = now
			@timer -= sec_elapsed
		end
	end
	def pause
		if is_time_left? && !@on_pause
			check
			@on_pause = true
		end
	end
	def self.add_0(time)
		if time < 10
			"0#{time}"
		else
			"#{time}"
		end
	end
	def show
		check
		if is_time_left?
			"#{Timer::add_0(hour)}:#{Timer::add_0(min)}:#{Timer::add_0(sec)}"
		else
			"Время вышло!"
		end
	end
end
