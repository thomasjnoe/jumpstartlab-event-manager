#!/usr/bin/env ruby
require "csv"
require "sunlight/congress"
require "erb"
require "time"

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5,"0")[0..4]
end	

def legislators_by_zipcode(zipcode)
	Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id,form_letter)
	Dir.mkdir("output") unless Dir.exists?("output")

	filename = "output/thanks_#{id}.html"

	File.open(filename,'w') { |file| file.puts(form_letter) }
	puts "#{filename} saved!"
end

def display_peak_registrations(hash, title)
	puts "\n--- Peak Registration #{title} ---"
	hash.sort_by { |k,v| v }.reverse[0..9].each_with_index do |pair, idx|
		puts "#{idx+1}. #{pair[0]} - #{pair[1]} registrations"
	end
end

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read("form_letter.erb")
erb_template = ERB.new(template_letter)
days = Hash.new(0)
hours = Hash.new(0)

puts "Saving thank you letters..."

contents.each do |row|
	id = row[0]
	reg_date = Time.strptime(row[:regdate], '%m/%d/%y %H:%M')
	name = row[:first_name]
	zipcode = clean_zipcode(row[:zipcode])
	legislators = legislators_by_zipcode(zipcode)

	form_letter = erb_template.result(binding)

	days[reg_date.strftime("%A")] += 1
	hours[reg_date.strftime("%l%p")] += 1

	save_thank_you_letters(id,form_letter)
end

puts "Thank you letters saved successfully"

display_peak_registrations(hours, "Hours")

display_peak_registrations(days, "Days")
