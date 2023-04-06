require "open-uri"
require "json"

line_width = 40
puts
puts "="*line_width
puts "Will you need an umbrella today?".center(line_width)
puts "="*line_width
puts
p "Where are you located?"
user_location = gets.chomp.capitalize

# Getting Google Maps API Data
gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{user_location}&key=" + ENV.fetch("GMAPS_KEY")
# p gmaps_url

gmaps_raw_response = URI.open(gmaps_url).read

gmaps_parsed_response = JSON.parse(gmaps_raw_response)

# p parsed_response.key

# parsing JSON file to retrieve latitude, longitude, and country from Google Maps API
results_array = gmaps_parsed_response.fetch("results")

first_result = results_array.at(0)
geo = first_result.fetch("geometry")
loc = geo.fetch("location")
latitude = loc.fetch("lat")
longitude = loc.fetch("lng")

address_components = first_result.fetch("address_components")

address_components.each do |add_comp|
  t = add_comp.fetch("types")

  if t.at(0) == "country"
    country_name = add_comp.fetch("long_name")
    puts "Looking up the weather for " + user_location + ", " + country_name + "..."
  end
end

puts "Your coordinates are #{latitude}, #{longitude}."

# Parsing JSON file to retrieve the weather from Pirate Weather API

pirate_weather_key = ENV.fetch("PIRATE_WEATHER_KEY")
pirate_url = "https://api.pirateweather.net/forecast/#{pirate_weather_key}/#{latitude},#{longitude}"

# p pirate_url

pirate_raw_response = URI.open(pirate_url).read

pirate_parsed_response = JSON.parse(pirate_raw_response)

currently_hash = pirate_parsed_response.fetch("currently")

current_temp = currently_hash.fetch("temperature")

puts
puts "It is currently #{current_temp}°F."
puts

## Getting the next hour weather forecast

hourly_hash = pirate_parsed_response.fetch("hourly")

hourly_summary = hourly_hash.fetch("summary")

puts "For the next hour, the weather is #{hourly_summary}"

hourly_data_array = hourly_hash.fetch("data")

next_twelve_hours = hourly_data_array[1..12]

precip_prob_threshold = 0.10
precipitation = false

next_twelve_hours.each do |hour_hash|
  precip_prob = hour_hash.fetch("precipProbability")
  if precip_prob > precip_prob_threshold
    precipitation = true
    precip_time = Time.at(hour_hash.fetch("time"))

    seconds_from_now = precip_time - Time.now

    hours_from_now = seconds_from_now / 60 / 60
    
    puts "In #{hours_from_now.round} hours, there is a #{(precip_prob * 100).round}% chance of precipitation."
  end
end

if precipitation == true
  puts "Looks like there's rain in the forecast for today. You might want to take an umbrella!"
else
  puts "Looks like there's no forecast of rain today.You probably won't need an umbrella today."
end
