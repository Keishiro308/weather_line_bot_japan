namespace :scheduler do
  desc "This task is called by the Heroku scheduler add-on"
  task :update_feed => :environment do
    require 'line/bot'  # gem 'line-bot-api'
    require 'open-uri'
    require 'kconv'
    require 'rexml/document'

    client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
    users = User.all
    users.each do |user|
      url  = "https://www.drk7.jp/weather/xml/#{user.pref_id}.xml"
      xml  = open( url ).read.toutf8
      doc = REXML::Document.new(xml)
      xpath = "weatherforecast/pref/area[#{user.city_id}]/info/rainfallchance/"
      per06to12 = doc.elements[xpath + 'period[2]'].text
      per12to18 = doc.elements[xpath + 'period[3]'].text
      per18to24 = doc.elements[xpath + 'period[4]'].text
      min_per = 20
      if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
        word1 =["おはようございます！","今日も1日が始まりますね！","よく眠れましたか？"].sample
        word2 =["良い一日を^^","今日も1日張り切っていきましょう！"].sample
        mid_per = 50
        if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i >= mid_per
          word3 = "今日は雨が降りそうなので傘をお忘れなく！"
        else
          word3 = "今日は雨が降るかもしれないので折りたたみ傘があると安心かもしれません！"
        end
        push ="#{word1}\n#{word3}\n降水確率はこのような感じです。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word2}"
        message = {
          type: 'text',
          text: push
        }
        response = client.push_message(user.line_id, message)
      end
      "OK"
    end
  end
end
