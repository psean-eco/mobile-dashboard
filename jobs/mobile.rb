require 'net/https'
require 'json'

labels = [ 'Fail', 'Pass', 'Skip' ]

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '10s', :first_in => 0 do |job|

  http = Net::HTTP.new("jenkinsqa.ecobee.com")
  jobs = [ "Android_Hyperion_Test_5.1", "Android_Hyperion_Test_6.0", "Android_Hyperion_Test_6.0.1", "Android_Hyperion_Installation_Wizard_Test_6.0.1",
           "iOS_Hyperion_Tests_10.0.1", "iOS_Hyperion_Tests_10.2.1", "iOS_Hyperion_Tests_10.3.2", "iOS_Hyperion_Tests_9.3.2", "iOS_Hyperion_Installation_Wizard_Test_10.2.1"]

  android_job_index = 1
  ios_job_index = 1

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
                '#F7464A',
                '#46BFBD',
                '#FDB45C',
            ],
            hoverBackgroundColor: [
                '#FF6384',
                '#36A2EB',
                '#FFCE56',
            ],
        },
    ]
    options = { }

    if job_name.include? "Android"
      send_event("doughnutchart_android_" + android_job_index.to_s, { labels: labels, datasets: data, title: job_name, duration: Time.at(duration).utc.strftime("%H:%M:%S"), options: options})
      android_job_index += 1

    elsif job_name.include? "iOS"
      send_event("doughnutchart_ios_" + ios_job_index.to_s, { labels: labels, datasets: data, title: job_name, duration: Time.at(duration).utc.strftime("%H:%M:%S"), options: options})
      ios_job_index += 1
    end

  end

end