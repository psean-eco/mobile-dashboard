require 'net/https'
require 'json'

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '10s', :first_in => 0 do |job|

  http = Net::HTTP.new("jenkinsqa.ecobee.com")
  jobs = [ "Android_Hyperion_Canary_Test_5.1",
           "Android_Hyperion_Distribution_Test",
           "Android_Hyperion_Test_5.1",
           "Android_Hyperion_Test_6.0",
           "Android_Hyperion_Test_6.0.1",
           "Android_Hyperion_Test_7.1.1",
           "Android_Hyperion_Installation_Wizard_Test_6.0.1",
           "iOS_Hyperion_Canary_Test_10.0.1",
           "iOS_Hyperion_Distribution_Test",
           "iOS_Hyperion_Tests_10.0.1",
           "iOS_Hyperion_Tests_10.2.1",
           "iOS_Hyperion_Tests_10.3.2",
           "iOS_Hyperion_Tests_9.3.2",
           "iOS_Hyperion_Installation_Wizard_Test_10.2.1" ]

  android_job_index = 1
  ios_job_index = 1

  jobs.each do |job_name|

    # first get last run status, if red mark as invalid
    response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/api/json?pretty=true"))
    results = JSON.parse(response.body)
    status = results["color"]

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

    # get last run build information (start time etc.)
    response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/lastCompletedBuild/api/json?pretty=true"))
    results = JSON.parse(response.body)
    timestamp = results["timestamp"]
    start = Time.at(timestamp.to_i / 1000).to_s
    start =~ /(.*) (.*)?/
    start = [ $1 << ' ', $2 ][0].strip

    if job_name.include? "Android"

      send_event("doughnutchart_android_" + android_job_index.to_s, { labels: labels, datasets: data, title: job_name,
                                                                      start: start, duration: duration, options: options})
      android_job_index += 1

    elsif job_name.include? "iOS"

      send_event("doughnutchart_ios_" + ios_job_index.to_s, { labels: labels, datasets: data, title: job_name,
                                                              start: start, duration: duration, options: options})
      ios_job_index += 1

    end

  end

end