require 'rubygems'
require 'mechanize'

class Scrap
	attr_reader :IDList, :property, :printResult #:IDListCount
	attr_writer :printResult

	def initialize
		@IDList = []
		#@IDListCount = 0
		@property = {}
		@property[:booked_nights]
		@property[:rates]
		@property[:images] = []

		@printResult = false

		@base_url = 'http://www.coastaljoevacationrentals.com'
		@property_list_url = '/site/PropertyList/5356/default.aspx'

		@calendar_table_id = 'ctl03_Panes_ThreePanes_ctl03_calMain_WeekRows'
		@calendar_table_booked_td_class = 'CSCDays2'

		@agent = Mechanize.new
		@agent.set_proxy 'mierem:password@proxy.softservecom.com', 8080
		@root = @agent.get(@base_url)
	end # def initialize
	
	def get_all_remote_ids
		link = @root.link_with(:href => @property_list_url)
		page = link.click if !link.nil?

		while link.attributes[:disabled].nil?#true#!link.nil? && !page.nil? && @IDListCount < 10 do
			
			link = page.link_with(:text => '>')

			page = link.click
			
			property_links = page.links()

			property_links.each do |property_link|
				property_link_href = property_link.href

				property_id_url = (/\/site\/Overview\/PropertyID__\d*\//).match(property_link_href)
				property_id = /\d{1,}/.match(property_id_url.to_s)
			
				@IDList.push(property_id) if !property_id.nil?
				#@IDListCount = @IDListCount + 1 if !property_id.nil?
			end
		end

	end # def get_all_remote_ids
	
	def fill_booked_nights(remote_id)
		#@property[:booked_nights]

		if @printResult
			puts ''
			puts '===fill_booked_nights==='
			puts ''
		end

		calendar_page = @agent.get(@base_url + '/site/Availability/PropertyID__' << remote_id.to_s << '/5370/default.aspx')

		time = Time.now
		month = 0
		booked_nights = []
		booked_nights_count = nil
		booked_nights_count = nil
		iterated_days_count = nil

		form = calendar_page.forms.first

      	12.times do
      		month = month + 1
      		date = Date.new(time.year, month)
      		form["__EVENTTARGET"] = "ctl03$Panes$ThreePanes$ctl03$calMain"
      		form["__EVENTARGUMENT"] = "_MYP"
      		form["ctl03$Panes$ThreePanes$ctl03$calMain_MYP_PN_Month"] = date.month
      		form["ctl03$Panes$ThreePanes$ctl03$calMain_MYP_PN_Year"] = date.year

      		calendar_page = form.submit

      		calendar_table = calendar_page.at('//table[@id="' << @calendar_table_id << '"]')
      		calendar_table = Nokogiri::HTML(calendar_table.to_s)
      		calendar_table_td = calendar_table.xpath('//td')

      		month_started = false
      		iterated_days_count = 0
      		booked_nights_count = 0

      		calendar_table_td.each do |td|
      			break if month_started && iterated_days_count > 1 && td.text.to_i == 1
      			if td.text.to_i == 1 || month_started
      				month_started = true
      				if td.attributes['class'].to_s == @calendar_table_booked_td_class.to_s
      					booked_nights << Date.new(date.year, date.month, td.text.to_i)
      					booked_nights_count = booked_nights_count + 1
      				end
      				iterated_days_count = iterated_days_count + 1
      			end
      		end

      		if @printResult
      			puts 'for ' << month.to_s << ' month ' << booked_nights_count.to_s << ' nights are booked'
      		end

      	end

      	if @printResult
      		puts ''
      		puts 'for id=' << remote_id.to_s << ' booked nights dates:'
      		puts ''
      		puts booked_nights
      	end
      	#puts ''

	end # def fill_booked_nights
	
	def fill_rates(remote_id)
		#rate = {:title => 'Low', :night => 200, :first_night => Date.new, :last_night => Date.new.next_year}
		#@property.rates << rate

		if @printResult
			puts ''
			puts '===fill_rates==='
			puts ''
		end

		description_page = @agent.get(@base_url + '/site/Overview/PropertyID__' << remote_id.to_s << '/5366/default.aspx')
		
		span_rate = description_page.at('//span[@class="Stat_Major Stat_Rate"]')
		rate = span_rate.text
		
		if @printResult
			puts rate
		end
	end # def fill_rates
	
	def fill_description(remote_id)
		#@property[:title]
		#@property[:summary]
		#@property[:description]
		#@property[:max_occupancy]

		if @printResult
			puts ''
			puts '===fill_description==='
			puts ''
		end

		description_page = @agent.get(@base_url + '/site/Overview/PropertyID__' << remote_id.to_s << '/5366/default.aspx')
		
		span_title = description_page.at('//td[@class="MOD_Title"]/span')
		title = span_title.text
		
		desctiption_content = description_page.at('//td[@class="Content_Center_Col"]')
		
		summary_regexp = Regexp.new(/^[A-Z\s]*$/)
		summary = summary_regexp.match(desctiption_content.text)[0]
		
		description = desctiption_content.text.gsub(summary_regexp, '')
		
		span_max_occupancy = description_page.at('//span[@class="Stat_Major"]')
		max_occupancy = span_max_occupancy.text
		
		if @printResult
			puts 'title: ' << title.to_s
			puts 'summary: ' << summary.to_s
			puts 'description: ' << description.to_s
			puts 'max max_occupancy: ' << max_occupancy.to_s
		end
	end # def fill_description
	
	def fill_images(remote_id)

		if @printResult
			puts ''
			puts '===fill_images==='
			puts ''
		end

		images_page = @agent.get(@base_url + '/site/Imagery/PropertyID__' << remote_id.to_s << '/5367/default.aspx')
		form = images_page.forms.first
		buttons = form.buttons_with(:class => 'Image_Thumb')
		buttons.each do |button|
			full_image_page = @agent.submit(form, button)
			image_source = full_image_page.image_with(:class => 'Image_Standard')
			image = {:src => image_source.src, :alt => image_source.alt.nil? ? '' : image_source.alt}
			@property[:images] << image
			#puts images
		end

		if @printResult
			puts @property[:images]
		end

	end # def fill_images
	
	private
	
	#@property = {}
	#@property[:booked_nights]
	#@property[:rates]
	#@property[:images] = []
	
	#end
	
end # class Scrap

scrap = Scrap.new
scrap.printResult = true

scrap.get_all_remote_ids
IDList = scrap.IDList.uniq!
puts 'all properties count ' << IDList.size.to_s

@IDListCount = IDList.size

#time_before = Time.now
#puts 'time before ' << time_before.to_s

IDList.each do |id|
	puts 'current id ' << id.to_s
	scrap.fill_images(id)
	scrap.fill_description(id)
	scrap.fill_rates(id)
	scrap.fill_booked_nights(id)

	#@IDListCount = @IDListCount - 1
	#puts 'remaining ' << IDListCount.to_s << ' properties'
	break
end

#time_after = Time.now
#puts 'time after ' << time_after.to_s

#puts 'time elapsed ' << (time_after - time_before).to_s

#puts scrap.property[:images]