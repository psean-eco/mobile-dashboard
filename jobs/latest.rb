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

  failed_test_case_tracker_android = Hash.new(0)
  failed_test_case_tracker_ios = Hash.new(0)

  test_case_breakdown_android = Hash.new(0)
  test_case_breakdown_ios = Hash.new(0)

  not_run_flag = true

  JOBS.each do |job_name, device_info|

    data = []

    # get last run build information (start time etc.)
    response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/lastCompletedBuild/api/json?pretty=true"))
    results = JSON.parse(response.body)
    timestamp = results["timestamp"]
    start = Time.at(timestamp.to_i / 1000)
    day_of_week = start.strftime("%A")

    start = start.to_s
    start =~ /(.*) (.*)?/
    start = [ $1 << ' ', $2 ][0].strip
    start = day_of_week + ", " + start

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

      not_run = 0
      flaky_fails = 0

      cases = results["suites"][0]["cases"]
      cases.each do |test_case|

        # track tests that did not run (failed to init)
        if test_case["name"].nil?

          not_run += 1

          # to account for flaky, track not run
          not_run_flag = true

        end

        if test_case["status"].include? "FAILED" or test_case["status"].include? "REGRESSION"

          # if previous test case was not run and this is fail or regression, not run is invalid
          if not_run_flag

            not_run -= 1
            not_run_flag = false
            flaky_fails += 1

          end

          if job_name.include? "Android"

            failed_test_case_tracker_android[test_case["className"]] += 1

          elsif job_name.include? "iOS"

            failed_test_case_tracker_ios[test_case["className"]] += 1

          end

        end

        # gather test case breakdown [category, number]
        test_class_name = test_case["className"]

        if test_class_name.include? "pytest"

          next

        end

        if test_class_name.include? ".page."

          test_class_name = test_class_name.split(".page.")[1].split(".")[0]

        elsif test_class_name.include? ".common."

          if test_class_name.include? "installation"

            test_class_name = "installation_" + test_class_name.split("ecobee")[1].split(".")[1]

          else

            test_class_name = test_class_name.split(".common.")[1].split(".")[0]

          end

        elsif test_class_name.include? ".e2e."

          test_class_name = test_class_name.split(".e2e.")[1].split(".")[0]

        end

        if job_name.include? "Android"

          test_case_breakdown_android[test_class_name] += 1

        elsif job_name.include? "iOS"

          test_case_breakdown_ios[test_class_name] += 1

        end

      end

      # retrieving relevant data
      duration = Time.at(results["duration"]).utc.strftime("%H:%M:%S")
      skip = results["skipCount"]

      # subtract not run and flaky fails from pass
      pass = (results["passCount"].to_i - not_run - flaky_fails).to_s

      # add not run to fail
      fail = (results["failCount"].to_i + not_run).to_s

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


  failed_test_case_tracker_android.each do |failed_test_case, occurrence|

    failed_test_case_tracker_android[failed_test_case] = { label: failed_test_case,
                                                           value: occurrence }

  end

  send_event('fail_tracker_android', { items: failed_test_case_tracker_android.values })

  failed_test_case_tracker_ios.each do |failed_test_case, occurrence|

    failed_test_case_tracker_ios[failed_test_case] = { label: failed_test_case,
                                                       value: occurrence }

  end

  send_event('fail_tracker_ios', { items: failed_test_case_tracker_ios.values })

  # automation test breakdown

  test_case_breakdown_android = test_case_breakdown_android.to_a.unshift(["Test Category", "Count"])
  send_event('pie_android', slices: test_case_breakdown_android)

  test_case_breakdown_ios = test_case_breakdown_ios.to_a.unshift(["Test Category", "Count"])
  send_event('pie_ios', slices: test_case_breakdown_ios)

end