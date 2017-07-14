require 'net/https'
require 'json'
require_relative "constants"

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0 do |job|

  http = Net::HTTP.new("jenkinsqa.ecobee.com")

  job_index_android = 1
  job_index_ios = 1

  running_android = 0
  running_ios = 0

  JOBS.each do |job_name, device_info|

    # get last run build information (start time etc.)
    response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/lastCompletedBuild/api/json?pretty=true"))
    results = JSON.parse(response.body)
    timestamp = results["timestamp"]
    start = Time.at(timestamp.to_i / 1000).to_s
    start =~ /(.*) (.*)?/
    start = [ $1 << ' ', $2 ][0].strip

    # first get last run status, report appropriate message if disabled, aborted or failed
    response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/api/json?pretty=true"))
    results = JSON.parse(response.body)
    status = results["color"]

    # check if current build is running a job
    if status.include? "_anime"

      if job_name.include? "Android"

        running_android += 1

      elsif job_name.include? "iOS"

        running_ios += 1

      end

    end

    # evaluate latest build status
    if status.include? "disabled"

      duration = "disabled"

    elsif status.include? "aborted"

        duration = "aborted"

    elsif status.include? "red"

      duration = "failed"

    else

      response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/lastCompletedBuild/testReport/api/json?pretty=true"))
      results = JSON.parse(response.body)

      # retrieving relevant data
      duration = Time.at(results["duration"]).utc.strftime("%H:%M:%S")
      fail = results["failCount"]
      pass = results["passCount"]
      skip = results["skipCount"]

      labels = [ fail, pass, skip ]

      data = [
          {
              data: [ fail, pass, skip ],
              backgroundColor: [
                  '#c9413c',
                  '#4bbe79',
                  '#727272',
              ],
              hoverBackgroundColor: [
                  '#e9b1af',
                  '#b4e4c7',
                  '#cccccc',
                ],
          },
      ]

    end

    options = { }

    job = job_name.dup

    if job.include? "Android"

      job.sub! "Android_", ""

      job.gsub! "_", " "

      send_event("doughnut_android_" + job_index_android.to_s, { labels: labels, datasets: data, title: job, device: device_info,
                                                                 start: start, duration: duration, options: options})
      job_index_android += 1

    elsif job.include? "iOS"

      job.sub! "iOS_", ""

      job.gsub! "_", " "

      send_event("doughnut_ios_" + job_index_ios.to_s, { labels: labels, datasets: data, title: job, device: device_info,
                                                         start: start, duration: duration, options: options})

      job_index_ios += 1

    end

  end

  send_event('running_android',   { value: running_android, max: job_index_android })
  send_event('running_ios',   { value: running_ios, max: job_index_ios })

end