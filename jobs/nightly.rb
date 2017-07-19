require 'net/https'
require 'json'
require_relative "constants"

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.cron '8 0 * * *' do

  platform_counts = Hash.new({ value: 0 })

  android_pass = 0
  android_fail = 0
  android_skip = 0

  ios_pass = 0
  ios_fail = 0
  ios_skip = 0

  not_run_flag = true

  http = Net::HTTP.new("jenkinsqa.ecobee.com")

  JOBS.each do |job_name, device_info|

    response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/api/json?pretty=true"))
    results = JSON.parse(response.body)
    builds = results["builds"]

    # check last 10 builds for nightly timestamp
    9.times do |i|

      build_number = builds[i]["number"]
      response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/" + build_number.to_s + "/api/json?pretty=true"))
      results = JSON.parse(response.body)
      timestamp = results["timestamp"]
      start = Time.at(timestamp.to_i / 1000)

      # only accept builds that ran last night between 7pm and 8am today
      if ((start.hour.to_i >= 19) or (start.hour.to_i <= 8)) and (start.day.to_i > Time.now.day.to_i - 1)

        # get run status of build, skip if running, aborted or failed
        status = results["result"]
        if (status.include? "FAILURE") or (status.include? "ABORTED") or (status.include? "null")

          next

        else

          response = http.request(Net::HTTP::Get.new("/jenkins/view/3.%20Mobile/job/" + job_name + "/" + build_number.to_s + "/testReport/api/json?pretty=true"))
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

            if test_case["status"].include? "FAILED"

              # if previous test case was not run and this is fail, not run is invalid
              if not_run_flag

                not_run -= 1
                not_run_flag = false
                flaky_fails += 1

              end

            end

          end

          if job_name.include? "Android"

            android_skip += results["skipCount"].to_i

            # subtract not run from pass
            android_pass += (results["passCount"].to_i - not_run - flaky_fails).to_i

            # add not run to fail
            android_fail += (results["failCount"].to_i + not_run).to_i

          elsif job_name.include? "iOS"

            ios_skip += results["skipCount"].to_i

            # subtract not run from pass
            ios_pass += (results["passCount"].to_i - not_run - flaky_fails).to_i

            # add not run to fail
            ios_fail += (results["failCount"].to_i + not_run).to_i

          end

        end

      end

    end

  end

  PLATFORMS.each do |platform|

    if platform.include? "Android"
      platform_counts[platform] = { label: platform,
                                    value_pass: android_pass.to_s,
                                    value_fail: android_fail.to_s,
                                    value_skip: android_skip.to_s }

    elsif platform.include? "iOS"
      platform_counts[platform] = { label: platform,
                                    value_pass: ios_pass.to_s,
                                    value_fail: ios_fail.to_s,
                                    value_skip: ios_skip.to_s }

    end

  end

  send_event('nightly', { items: platform_counts.values })

end