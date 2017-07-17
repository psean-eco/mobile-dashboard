#!/usr/bin/env ruby
require 'rubygems'
require 'market_bot'

# Find your apps package as part as Google Play url. i.e.
# Chrome's Google Play url is https://play.google.com/store/apps/details?id=com.android.chrome
# then Chrome's application package is com.android.chrome
apps_mapping = [
  'com.ecobee.athenamobile',
  'com.snapchat.android'
]

SCHEDULER.every '60s', :first_in => 0 do |job|
  data = { 
    :last_version => {
      average_rating: 0.0,
      voters_count: 0
    }
  }
  begin
    apps_mapping.each do |app_identifier|
      app = MarketBot::Play::App.new(app_identifier)
      app.update
      data[:last_version][:average_rating] = app.rating
      rating_detail = 0.0
      number_of_votes = 0
      app.rating_distribution.each { |rating_distribution|
        rating_detail += rating_distribution[0] * rating_distribution[1]
        number_of_votes += rating_distribution[1]
      }
      if number_of_votes > 0
        rating_detail = "%.4f" % (rating_detail / number_of_votes)
      end
      data[:last_version][:average_rating_detail] = rating_detail
      data[:last_version][:voters_count] = app.votes

      if defined?(send_event)
        send_event(app_identifier, data)
        print "google #{data}\n"
      end
    end
  rescue Exception => e
    puts "Error: #{e}"
  end
end