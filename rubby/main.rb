require './sense_scraper'

sense_username = ENV['SENSE_USERNAME']
sense_password = ENV['SENSE_PASSOWRD']
influx_token = ENV['SENSE_TOKEN']

scraper = Sense2Influx.new(sense_username: sense_username,
                           sense_password: sense_password,
                           influx_token: influx_token
                          )

scraper.scrape_metrics
