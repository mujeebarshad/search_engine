require 'geocoder' # calculating distance between geolocations
require 'json' # loading json
require 'string/similarity' # get value to distinguish the difference in strings
require "logger" # for logging

logger = Logger.new(STDOUT)

FILE_NAME = 'data.json'.freeze
SIMILARITY_THRESHOLD = 0.8
KILOMETER_IN_METERS = 1000
MAX_DECIMAL_ROUND = 3

def read_json_from_file(file_name)
	file = File.open(file_name)
	JSON.load(file)
rescue StandardError => e
	logger.info("Error loading json file! | reason: #{e.message}")
	[]
end

def calculate_distance_between_geo_locations(first_geo_location, second_geo_location)
	first_geo_location 	= first_geo_location.values
	second_geo_location = second_geo_location.values
	return -1 if first_geo_location == nil || second_geo_location == nil

	Geocoder::Calculations.distance_between(first_geo_location, second_geo_location, units: :km)
end

def distinguish_and_arrange_distance(distance)
	if distance < 1
    "#{(distance * KILOMETER_IN_METERS).round(MAX_DECIMAL_ROUND)}m"
  else
    "#{distance.round(MAX_DECIMAL_ROUND)}km"
  end
end

def create_json_result(results, total_data)
	{
		"totalHits": results.length,
    "totalDocuments": total_data,
    "results": results
	}.to_json
end

def search_engine(service_name, geo_location) # params => string, hash {lat, long}
	location_of_services = read_json_from_file(FILE_NAME)
	result = []
	total_locations = location_of_services.length
	return create_json_result(result, total_locations) if service_name.empty? || geo_location.empty? # in case empty data we return 0 hits

	location_of_services.each do |service_location|
		similarity_score = String::Similarity.cosine(service_location['name'], service_name) # string difference score
		next if similarity_score < SIMILARITY_THRESHOLD

		distance_between_locations = calculate_distance_between_geo_locations(geo_location, service_location['position'])
		next if distance_between_locations == -1

		service_location['distance'] = distinguish_and_arrange_distance(distance_between_locations)
		service_location['score'] 	 = similarity_score
		result.push(service_location)
	end
	create_json_result(result, total_locations)
end

puts "Serivce Name: "
service_name = gets.chomp
puts "Latitude: "
latitude = gets.chomp.to_f
puts "Longitude: "
longitude = gets.chomp.to_f
p search_engine(service_name, { 'lat' => latitude, 'lng' => longitude })

# Test Scenario
# p search_engine('Ansiktsmassage', { 'lat' => 59.44411099999999, 'lng' => 18.149118499999963 })