require 'sinatra'
require 'securerandom'
require 'mongo'
require 'json/ext' # required for .to_json
require "digest"
require 'uri'
require 'httparty'



configure do
  if settings.development?
    dbname = "test"
    db = Mongo::Client.new(['127.0.0.1:27017'], :database => dbname)
  else
    dbname = ENV['MONGODB_URI'].split("/").last
    db = Mongo::Client.new(ENV['MONGODB_URI'], :database => dbname)
  end
  set :mongo_db, db[dbname.to_sym]
  set :server, :puma
  set :bind, "0.0.0.0"
  set :protection, except: [:frame_options, :json_csrf]
  set :root, File.dirname(__FILE__)

  # this added in attempt to "forbidden" response when clicking on links
  #set :protection, :except => :ip_spoofing
  #set :protection, :except => :json
end

if settings.development?
  require 'pry'
end

get '/' do
  erb :index
end
get '/rubric/:society' do |society|
  if society == "maa"
    erb :maa_rubric
  end
end
get '/reviews' do
  @reviews = []

  db = settings.mongo_db
  db.find().map {|object|
    @reviews << object
  }
  erb :reviews
end
get '/about' do
  erb :about
end
# find a document by its Mongo ID
get '/document/:id/?' do
  content_type :json
  document_by_id(params[:id])
end

get '/reviews/create' do
  erb :create
end

post '/reviews/create' do
  id = SecureRandom.uuid
  date = Time.new
  review_text_url = params[:review_text_url]
  review_society = params[:review_society]
  review_summary = params[:review_summary]
  review_badge_number = params[:review_badge_number]
  if review_badge_number == "1"
    review_badge = "http://dll-review-registry.herokuapp.com/maa-badge-working.svg"
    badge_rubric = "http://dll-review-registry.herokuapp.com/rubric/maa#green"
  elsif review_badge_number == "2"
    review_badge = "http://dll-review-registry.herokuapp.com/maa-badge.svg"
    badge_rubric = "http://dll-review-registry.herokuapp.com/rubric/maa#gold"
  end

  response = HTTParty.get(review_text_url)
  shasum = Digest::SHA2.hexdigest(response.body)


  review_content =  {
      "@id": "http://digitallatin.org/reviews/#{id}",
      "review-metadata":
      {
          "review-society": review_society,
          "date": date,
          "badge-url": review_badge,
          "badge-rubric": badge_rubric,
          "review-report": "http://digitallatin.org/#{id}/report",
          "review-summary": review_summary,
          "origin-source": {
            "github-url": review_text_url,
            "shasum": shasum,
          },
          "dll-source": {
            "git-url": review_text_url,
            "shasum": shasum,
          }
      }
  }
  filename = "public/" + id + '.json'
  final_content = JSON.pretty_generate(review_content)
  db = settings.mongo_db
  db.insert_one(review_content)
  File.open(filename, 'w') { |file|
    file.write(final_content)
  }
  @id = id
  erb :create_completed

end

get '/reviews/:id.json' do |id|
  headers( "Access-Control-Allow-Origin" => "*")
  content_type :json
  db = settings.mongo_db
  document = db.find( { "@id": "http://digitallatin.org/reviews/#{id}" } ).to_a.first
  (document || {}).to_json

end
get '/reviews/:id.html' do |id|
  db = settings.mongo_db
  @document = db.find( { "@id": "http://digitallatin.org/reviews/#{id}" } ).to_a.first
  @id = @document["@id"].to_s.split("http://digitallatin.org/reviews/").last()
  erb :show
end

helpers do
  # a helper method to turn a string ID
  # representation into a BSON::ObjectId
  def object_id val
    begin
      BSON::ObjectId.from_string(val)
    rescue BSON::ObjectId::Invalid
      nil
    end
  end

  def document_by_id id
    id = object_id(id) if String === id
    if id.nil?
      {}.to_json
    else
      document = settings.mongo_db.find(:_id => id).to_a.first
      (document || {}).to_json
    end
  end
end
