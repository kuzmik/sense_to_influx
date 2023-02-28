require 'unofficial_sense_api'
require 'influxdb-client'
require 'pry'

class Sense2Influx
  @verbose = false

  def initialize(sense_username:, sense_password:, influx_token:)
    @verbose = true

    @influx = InfluxDB2::Client.new('http://localhost:8086',
                                    influx_token,
                                    org: 'infra',
                                    bucket: 'sense',
                                    precision: InfluxDB2::WritePrecision::NANOSECOND,
                                    use_ssl: false
                                  )

    @sense = SenseApi.new(sense_username, sense_password)
  end

  # Get the metrics from the sense api and submit them to the configured
  # influxdb server
  def scrape_metrics()
    write_api = @influx.create_write_api
    begin
      @sense.realtime do |results|
        next unless devices = results.dig('payload').dig('devices')

        puts "Got devices: #{devices.collect {|x| x['name']}.join(', ')}" if @verbose

        system_point = InfluxDB2::Point.new(name: 'system')
                                       .add_field('hertz', results.dig('payload')['hz'])
                                       .add_field('watts', results.dig('payload')['w'])
                                       .add_field('cost', results.dig('payload')['c'])
                                       .time(Time.now.utc, InfluxDB2::WritePrecision::NANOSECOND)

        write_api.write(data: system_point, bucket: 'sense', org: 'infra')
        puts system_point.to_line_protocol if @verbose

        # cycle through and get the stats for each device
        devices.each do |device|
          device_name = device['name'].downcase.tr('-', '').tr(' ', '_')

          point = InfluxDB2::Point.new(name: 'devices')
                                  .add_tag('id', device['id'])
                                  .add_tag('name', device_name)
                                  .add_field('watts', device['w'])
                                  .time(Time.now.utc, InfluxDB2::WritePrecision::NANOSECOND)

          point.add_tag('location', device['given_location'].downcase) if device['given_location']

          write_api.write(data: point, bucket: 'sense', org: 'infra')
          puts "  #{point.to_line_protocol}" if @verbose
        end

        sleep 5
      end
    rescue SenseApi::SenseApiError => ex
      puts ex
      retry
    end
  end
end
