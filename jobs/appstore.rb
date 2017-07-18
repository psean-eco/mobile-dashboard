#!/usr/bin/env ruby
require 'net/http'
require 'openssl'

# Get info from the App Store of your App: 
# Last version Average and Voting
# All time Average and Voting
# 
# This job will track average vote score and number of votes  
# of your App by scraping the App Store website.

# Config
appPageUrl = '/us/app/ecobee/id916985674'

SCHEDULER.every '30m', :first_in => 0 do |job|
  puts "fetching App Store Rating for App: " + appPageUrl
  # prepare request  
  http = Net::HTTP.new("itunes.apple.com", Net::HTTP.https_default_port())
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # disable ssl certificate check

  # scrape detail page of appPageUrl
  response = http.request( Net::HTTP::Get.new(appPageUrl) )

  if response.code != "200"
    puts "App Store store website communication (status-code: #{response.code})\n#{response.body}"
  else
    data = { 
      :last_version => {
        average_rating: 0.0,
        voters_count: 0
      }
    }
    
    # Version: ... aria-label="4 stars, 2180 Ratings"
    average_rating = response.body.scan( /(Version(s)?:(.)*?aria-label=[\"\'](?<num>.*?)star)/m )
    print "#{average_rating}\n"
    # <span class="rating-count">24 Ratings</span>
    voters_count = response.body.scan( /(class=[\"\']rating-count[\"\']>(?<num>([\d,.]+)) )/m )
    print "#{voters_count}\n"

    # all and last versions average rating 
    if ( average_rating )
      if ( average_rating[0] ) # Last Version
        raw_string = average_rating[0][0].gsub('star', '')
        clean_string = raw_string.match(/[\d,.]+/i)[0]
        last_version_average_rating = clean_string.gsub(",", ".").to_f
        half = 0.0
        if ( raw_string.match(/half/i) )
          half = 0.5
        end
        last_version_average_rating += half
        data[:last_version][:average_rating] = "%.1f" % last_version_average_rating
        data[:last_version][:average_rating_detail] =  "%.2f" % last_version_average_rating
      else 
        puts 'ERROR::RegEx for last version average rating didn\'t match anything'
      end
    end

    # all and last versions voters count 
    if ( voters_count )
      if ( voters_count[0] ) # Last Version
        last_version_voters_count = voters_count[0][0].gsub(',', '').to_i
        data[:last_version][:voters_count] = last_version_voters_count
      else 
        puts 'ERROR::RegEx for last version voters count didn\'t match anything'
      end
    end

    if defined?(send_event)
      send_event('app_store_rating', data)
      print "iOS #{data}\n"
    else
      print "#{data}\n"
    end
  end
end