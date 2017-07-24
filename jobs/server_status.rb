#!/usr/bin/env ruby
require 'net/http'
require 'uri'

# Check whether a server is responding
# you can set a server to check via http request or ping
#
# server options:
# name: how it will show up on the dashboard
# url: either a website url or an IP address (do not include https:// when usnig ping method)
# method: either 'http' or 'ping'
# if the server you're checking redirects (from http to https for example) the check will
# return false

servers = [{name: 'Android (Develop)', job_name: 'ecobee3%20Mobile%20Android%20(Develop)', method: 'status'},
					 {name: 'Android (version 4.0.0 beta-1-CFT1)', job_name: 'ecobee3%20Mobile%20Android%20(version%204.0.0%20beta-1-CFT1)', method: 'status'},
					 {name: 'iOS (Beta Ad-hoc)', job_name: 'Native%20iOS/job/Native%20iOS%20(develop)', method: 'status'},
					 {name: 'iOS (Develop Ad-hoc)', job_name: 'Native%20iOS/job/Native%20iOS%20(develop)', method: 'status'},
					 {name: 'iOS (Release Ad-hoc)', job_name: 'Native%20iOS/job/Native%20iOS%20(develop)', method: 'status'}]

http = Net::HTTP.new("mobile-ci-server.ecobee.com", "8080")

SCHEDULER.every '1m', :first_in => 0 do |job|

	statuses = Array.new

	# check status for each server
	servers.each do |server|

    if server[:job_name].include? "Android"
			request = Net::HTTP::Get.new("/view/Android%20Mobile/job/" + server[:job_name] + "/lastCompletedBuild/api/json?pretty=true")
			request.basic_auth("qauser", "passwordQA1")
      response = http.request(request)
			results = JSON.parse(response.body)
      status = results["result"]

			if status == "SUCCESS"
				result = 1
			else
				result = 0
      end

		end

		if result == 1
			arrow = "icon-ok-sign"
			color = "green"
		else
			arrow = "icon-warning-sign"
			color = "red"
		end

    tmp = {label: server[:name], value: result, arrow: arrow, color: color}
    puts tmp
		statuses.push({label: server[:name], value: result, arrow: arrow, color: color})
	end

	# print statuses to dashboard
	send_event('server_status', {items: statuses})
end