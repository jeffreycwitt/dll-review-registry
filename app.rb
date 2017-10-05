require 'sinatra'
require 'securerandom'
require 'mongo'
require 'json/ext' # required for .to_json
require "digest"
require 'multihashes'
require 'uri'
require 'httparty'
require 'base58'


configure do
  if settings.development?
    dbname = "test"
    db = Mongo::Client.new(['127.0.0.1:27017'], :database => dbname)
  elsif settings.environment == :docker
    dbname = "test"
    db = Mongo::Client.new(['mongodb:27017'], :database => dbname)
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

  digest = Digest::SHA256.digest(response.body)
  multihash_binary_string = Multihashes.encode digest, 'sha2-256'


  hexmulti = multihash_binary_string.unpack('H*').first
  puts hexmulti




  filename = review_text_url.split('/').last
  File.open("tmp/#{filename}", 'w') { |file|
    file.write(response.body)
  }
  puts "IPFS test"
  ipfs_report = `ipfs add "tmp/#{filename}"`
  puts ipfs_report
  ipfs_hash = ipfs_report.split(" ")[1]


  review_content =  {
      "id": id,
      "review-society": review_society,
      "date": date,
      "badge-url": review_badge,
      "badge-rubric": badge_rubric,
      "review-report": nil,
      "review-summary": review_summary,
      "sha-256": shasum,
      "ipfs-hash": ipfs_hash,
      "git-blob-hash": nil,
      "url": review_text_url
  }
  #filename = "public/" + id + '.json'
  #final_content = JSON.pretty_generate(review_content)
  db = settings.mongo_db
  db.insert_one(review_content)
  #File.open(filename, 'w') { |file|
  #  file.write(final_content)
  #}
  @id = id
  erb :create_completed

end

get '/reviews/:id.json' do |id|
  headers( "Access-Control-Allow-Origin" => "*")
  content_type :json
  db = settings.mongo_db
  document = db.find( { "id": "#{id}" } ).to_a.first
  (document || {}).to_json

end
get '/reviews/:id.html' do |id|
  db = settings.mongo_db
  @document = db.find( { "id": "#{id}" } ).to_a.first
  @id = @document["@id"]
  erb :show
end

get '/hash/:hash.json' do |id|
  headers( "Access-Control-Allow-Origin" => "*")
  content_type :json
  db = settings.mongo_db
  if id.start_with? "Qm"
    documents = db.find( { "review-metadata.ipfs-hash": "#{id}"}).to_a
  else
    documents = db.find( { "review-metadata.sha-256": "#{id}"}).to_a
  end
  (documents || {}).to_json
end
get '/hash/:hash.html' do |id|
  db = settings.mongo_db
  if id.start_with? "Qm"
    @documents = db.find( { "review-metadata.ipfs-hash": "#{id}"}).to_a
  else
    @documents = db.find( { "review-metadata.sha-256": "#{id}"}).to_a
  end
  erb :show_array
end
# api/v1 routes
get '/api/v1/text/:hash' do |id|
  headers( "Access-Control-Allow-Origin" => "*")
  content_type :json
  db = settings.mongo_db
  if id.start_with? "Qm"
    documents = db.find( { "ipfs-hash": "#{id}"}).to_a
  else
    documents = db.find( { "sha-256": "#{id}"}).to_a
  end
  (documents || {})

  response = documents.map{|doc|
    {
      "id": doc["id"],
      "review-society": doc["review-society"],
      "date": doc["date"],
      "badge-url": doc["badge-url"],
      "badge-rubric": doc["badge-rubric"],
      "review-report": doc["review-report"],
      "review-summary": doc["review-summary"],
      "sha-256": doc["sha-256"],
      "ipfs-hash": doc["ipfs-hash"],
      "git-blob-hash": doc["git-blob-hash"],
      "url": doc["url"]
    }

  }.to_json
end
get '/api/v1/review/:id' do |id|
  headers( "Access-Control-Allow-Origin" => "*")
  content_type :json
  db = settings.mongo_db

  doc = db.find( { "id": "#{id}" } ).to_a.first
  (doc || {})

  response = {
      "id": doc["id"],
      "review-society": doc["review-society"],
      "date": doc["date"],
      "badge-url": doc["badge-url"],
      "badge-rubric": doc["badge-rubric"],
      "review-report": doc["review-report"],
      "review-summary": doc["review-summary"],
      "sha-256": doc["sha-256"],
      "ipfs-hash": doc["ipfs-hash"],
      "git-blob-hash": doc["git-blob-hash"],
      "url": doc["url"]
  }.to_json
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
