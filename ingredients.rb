require 'httparty'
require 'sinatra'
require 'active_support/core_ext'
require 'dotenv'
Dotenv.load('.env')

API_KEY = ENV['API_KEY']

url = "https://api.spoonacular.com/recipes/findByIngredients"
endpoint = "?ingredients="
key_param = "&apiKey="
key_query = "?apiKey="
number = "&number=3"

def load_recipes(query, api, ingredients)
	titles = []
	images = []
	ings = []
	urls = []
	url = "https://api.spoonacular.com/recipes/findByIngredients"
	endpoint = "?ingredients="
	key_param = "&apiKey="
	key_query = "?apiKey="
	number = "&number=3"
	response = HTTParty.get(url + endpoint + ingredients + number + key_param + API_KEY, format: :plain)
	json = JSON.parse(response, symbolize_names: true).select { |option| option[:missedIngredientCount] <= 2 && option[:usedIngredientCount] >= 1}
	recipes = json
	recipes.each_with_index do |recipe, idx|
		puts "Loading Recipe No. #{idx + 1}"
		titles << recipe[:title]
		images << recipe[:image]
		id = recipe[:id]
		recipe[:missedIngredients].each {|ing| ings << ing[:name] }
		url_find = "https://api.spoonacular.com/recipes/#{id}/information"
		response_find = HTTParty.get(url_find + query + api, format: :plain)
		json_find = JSON.parse(response_find, symbolize_names: true)
		urls << json_find[:sourceUrl]
	end
	[titles, images, ings, urls]
end

def within_quota(query, api, ingredients = "Rib Eye Steak")
	get '/' do
		erb :index
	end

	post '/search' do
		@ingredients = params[:ingredients]
		recipe_data = load_recipes(query, api, @ingredients)
		@titles = recipe_data[0]
		@images = recipe_data[1]
		@ings = recipe_data[2]
		@urls = recipe_data[3]
		erb :search
	end
end 

def not_within_quota()
	get '/' do
		"Service Not Available: Exceeded Quota"
	end
end

response = HTTParty.get(url + "?ingredients=corned beef" + key_param + API_KEY, format: :plain)
requests = response.headers["x-api-quota-used".to_sym].to_i
puts requests
requests < 600 ? within_quota(key_query, API_KEY) : not_within_quota()