class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)
    events.each { |event|
     case event
       # メッセージが送信された場合の対応（機能①）
     when Line::Bot::Event::Message
       case event.type
         # ユーザーからテキスト形式のメッセージが送られて来た場合
       when Line::Bot::Event::MessageType::Text
         # event.message['text']：ユーザーから送られたメッセージ
         input = event.message['text']
         url  = "https://www.drk7.jp/weather/xml/27.xml"
         xml  = open( url ).read.toutf8
         doc = REXML::Document.new(xml)
         xpath = 'weatherforecast/pref/area[1]/'
         min_per = 30
         case input
         when /.*(明日|あした).*/
           per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
           per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
           per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text
           if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
             push =
               "明日の天気ですか。。。\n明日は雨が降りそうですね。\n今のところ降水確率はこのようになっております。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\nまた明日の朝の最新の天気予報で雨が降りそうだったらお伝えいたします！"
           else
             push =
               "明日の天気ですね。\n明日は雨が降らない予定です！\nまた明日の朝の最新の天気予報で雨が降りそうだったらお伝えいたします。"
           end
         when /.*(明後日|あさって|二日後|2日後|２日後).*/
           per06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]l'].text
           per12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]l'].text
           per18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]l'].text
           if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
             push =
               "明後日の天気ですか。。。\n非常に言いにくいのですが。。。\n明後日は雨が降りそうです。\n当日の朝に雨が降りそうだった場合、またお伝えいたします。"
           else
             push =
               "明後日の天気ですね？\n明後日は雨は降らない予定です。\nまた当日の朝の最新の天気予報で雨が降りそうだった場合お伝えいたします。！"
           end
         when /.*(明々後日|しあさって|三日後|3日後|３日後).*/
           per06to12 = doc.elements[xpath + 'info[4]/rainfallchance/period[2]l'].text
           per12to18 = doc.elements[xpath + 'info[4]/rainfallchance/period[3]l'].text
           per18to24 = doc.elements[xpath + 'info[4]/rainfallchance/period[4]l'].text
           if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
             push =
               "明々後日の天気ですか。。。\nまだまだ諦めるには早いですが\n明々後日は雨が降りそうです。\n当日の朝に雨が降りそうだった場合、またお伝えいたします。"
           else
             push =
               "明々後日の天気ですね？\n明々後日は雨は降らない予定です。\nまた当日の朝の最新の天気予報で雨が降りそうだった場合お伝えいたします。！"
           end
         when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
           push =
             "こんにちは。\n声をかけてくれてありがとうございます。\n今日があなたにとっていい日になりますように"
         else
           per06to12 = doc.elements[xpath + 'info/rainfallchance/period[2]l'].text
           per12to18 = doc.elements[xpath + 'info/rainfallchance/period[3]l'].text
           per18to24 = doc.elements[xpath + 'info/rainfallchance/period[4]l'].text
           if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
             word =
               ["雨ですが、負けずに行きましょう！",
                "雨に負けずファイトです！！",
                "止まない雨はありません。あ、こういうのは求めてませんか。。（汗）"].sample
             push =
               "今日の天気ですか？\n今日は雨が降りそうなので傘があった方が安心ですね。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word}"
           else
             word =
               ["洗濯日和ですね！",
                "散歩でもいかがですか？",
                "良い1日を"].sample
             push =
               "今日の天気ですね。\n今日は雨は降らなさそうです。\n#{word}"
           end
         end
       when Line::Bot::Event::MessageType::Location
         location = LocInfo.order(Arel.sql('pow((event["message"]["longitude"]-long),2)+pow((event["message"]["latitude"]-lat),2) ASC')).first
         User.update_columns(city_id: location.city_id, pref_id: location.pref_id)
         push = "天気を表示する地点を変更しました。"
         # テキスト以外（画像等）のメッセージが送られた場合
       else
         push = "テキスト以外はわかりません。"
       end
       message = {
         type: 'text',
         text: push
       }
       client.reply_message(event['replyToken'], message)
       # LINEお友達追された場合（機能②）
     when Line::Bot::Event::Follow
       # 登録したユーザーのidをユーザーテーブルに格納
       line_id = event['source']['userId']
       User.create(line_id: line_id)
       # LINEお友達解除された場合（機能③）
     when Line::Bot::Event::Unfollow
       # お友達解除したユーザーのデータをユーザーテーブルから削除
       line_id = event['source']['userId']
       User.find_by(line_id: line_id).destroy
     end
    }
    head :ok
  end

  private

  def client
   @client ||= Line::Bot::Client.new { |config|
     config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
     config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
   }
  end
end
