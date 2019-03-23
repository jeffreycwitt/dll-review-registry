def convertUrl(url) do
  newUrl = if params[:url].include? "https://gateway.scta.info" then
    url.gsub("https://gateway.scta.info", "http://localhost:8080")
  elsif params[:url].include? "http://gateway.scta.info"
    url.gsub("http://gateway.scta.info", "http://localhost:8080")
  else
    url
  end
end
