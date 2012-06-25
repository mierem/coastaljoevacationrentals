require 'rubygems'
require 'mechanize'

class Scrap
	attr_reader :IDList, :IDListCount

	def initialize
		@IDList = []
		@IDListCount = 0
		@agent = Mechanize.new
		@root = @agent.get('http://www.coastaljoevacationrentals.com/')
	end # def initialize
	
	def get_all_remote_ids
		link = @root.link_with(:href => '/site/PropertyList/5356/default.aspx')
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
				@IDListCount = @IDListCount + 1 if !property_id.nil?
			end

		end

	end # def get_all_remote_ids
	
	def fill_booked_nights(remote_id)
		#@property[:booked_nights]
	end # def fill_booked_nights
	
	def fill_rates(remote_id)
		#rate = {:title => 'Low', :night => 200, :first_night => Date.new, :last_night => Date.new.next_year}
		#@property.rates << rate
	end # def fill_rates
	
	def fill_description(remote_id)
		#@property[:title]
		#@property[:summary]
		#@property[:description]
		#@property[:max_occupancy]
	end # def fill_description
	
	def fill_images(remote_id)
		#image = {:src => '', :alt => 'Some title'}
		#@property[:images] << image
	end # def fill_images
	
	private
	
	@property = {}
	@property[:booked_nights] = []
	@property[:rates] = []
	@property[:images] = []
	
	#end
	
end # class Scrap

scrap = Scrap.new
scrap.get_all_remote_ids
puts scrap.IDList.uniq!
puts scrap.IDList.size