namespace :sampler do
  desc "This is the task to sample xml about location"
  task :sample_info => :environment do
    require 'open-uri'
    require 'kconv'
    require 'rexml/document'

    for pref_num in 1..47 do
      pref_num < 10 ? pref_id = "0" + pref_num.to_s : pref_id = pref_num
      url  = "https://www.drk7.jp/weather/xml/#{pref_id}.xml"
      xml  = open( url ).read.toutf8
      doc = REXML::Document.new(xml)
      path = 'weatherforecast/pref/'
      area_counts = doc.elements[path].elements.size
      for area_num in 1..area_counts do
        long = doc.elements[path + "area[#{area_num}]/geo/long"].text
        lat = doc.elements[path + "area[#{area_num}]/geo/lat"].text

        LocInfo.create(pref_id: pref_num, city_id: area_num, long: long.to_f, lat:lat.to_f)
      end
    end
  end
end
