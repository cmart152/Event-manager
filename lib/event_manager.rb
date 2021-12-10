require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'pry-byebug'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_number(number)
  def clean_phone_number(number)
    number.gsub!(/[^\d]/,'')
    
    if number.length == 11 && number[0] == "1"
       return number[1..-1]
    elsif number.length == 10
      return number
    else
      return "This number contains an error"
    end
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def peak_registration_calculation(hash)
  control_value = (hash.values.max.to_f / 100 * 66.6).round(2)
  peak_hash = {}
 
  hash.each do |key, value| if value > control_value
    peak_hash[key] = value
    end
  end
  return peak_hash
end

def peak_hours(hash)
  hours_array = Array.new()
  hours_array[0] = Time.strptime(hash.key(hash.values.min), '%k').strftime('%k:%M') 
  hours_array[1] = Time.strptime(hash.key(hash.values.max), '%k').strftime('%k:%M')
  return hours_array
end

def peak_registration_days(hash)
  days_array = hash.keys
end

puts 'EventManager initialized.'

attendees_short = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

attendees_full = CSV.open(
  'event_attendees_full.csv',
  headers: true,
  header_converters: :symbol
)

attendees_full_copy = CSV.open(
  'event_attendees_full.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


=begin 
attendees_short.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter) 
end
=end

registration_hours_hash = attendees_full.reduce(Hash.new(0)) do |hash, item|
  hash[Time.strptime(item[1], '%M/%d/%y %k:%M').strftime('%k')] += 1
  hash
  end

puts "\nThe peak hours for registration (within 66% of busiest hour) were between #{peak_hours(peak_registration_calculation(registration_hours_hash))[0]} and
#{peak_hours(peak_registration_calculation(registration_hours_hash))[-1]}" 


registration_days_hash = attendees_full_copy.reduce(Hash.new(0)) do |hash, item|
 
  case Time.strptime(item[1], '%M/%d/%y %k:%M').strftime('%A')
    when "Monday"
      hash["Monday"] += 1
    when "Tuesday"
      hash["Tuesday"] += 1
    when "Wednesday"
      hash["Wednesday"] += 1
    when "Thursday"
      hash["Thursday"] += 1
    when "Friday"
      hash["Friday"] += 1
    when "Saturday"
      hash["Saturday"] += 1
    when "Sunday"
      hash["Sunday"] += 1
    end
hash
end

puts "\nThe busiest days of the week (within 66% of busiest day) for registration are listed below 
#{peak_registration_calculation(registration_days_hash).keys.join("\n")}"
