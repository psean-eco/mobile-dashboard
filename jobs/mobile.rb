require 'net/https'
require 'json'

labels = [ 'Fail', 'Pass', 'Skip' ]

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '10s', :first_in => 0 do |job|

  http = Net::HTTP.new("jenkinsqa.ecobee.com")
  jobs = [ "Android_Hyperion_Test_5.1", "Android_Hyperion_Test_6.0", "Android_Hyperion_Test_6.0.1", "Android_Hyperion_Installation_Wizard_Test_6.0.1"]
  android_job_index = 0

  jobs.each do |job_name|

    response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/lastCompletedBuild/testReport/api/json?pretty=true"))
    results = JSON.parse(response.body)

    # retrieving relevant data
    duration = results["duration"]
    fail = results["failCount"]
    pass = results["passCount"]
    skip = results["skipCount"]

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
    options = { }
    send_event("doughnutchart_android_" + android_job_index.to_s, { labels: labels, datasets: data, title: job_name, duration: Time.at(duration).utc.strftime("%H:%M:%S"), options: options})
    android_job_index += 1

  end

end