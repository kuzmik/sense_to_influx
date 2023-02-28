import logging
import os

from retrying import retry
from sense_energy import Senseable
import influxdb_client
from influxdb_client.client.write_api import SYNCHRONOUS

influx_url = os.environ['INFLUX_URL'] or "http://localhost:8086"
org = os.environ['INFLUX_ORG']
bucket = os.environ['INFLUX_BUCKET']
influx_token = os.environ['INFLUX_TOKEN']
sense_username = os.environ['SENSE_USERNAME']
sense_password = os.environ['SENSE_PASSWORD']

ifc = influxdb_client.InfluxDBClient(
   url=influx_url,
   token=influx_token,
   org=org
)
write_api = ifc.write_api(write_options=SYNCHRONOUS)

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

@retry(wait_exponential_multiplier=1000, wait_exponential_max=10000)
def read_realtime_metrics():
  try:
    sense = Senseable()
    sense.authenticate(sense_username, sense_password)

    for results in sense.get_realtime_stream():
      hwatts = results.get('w')
      cost = results.get('c')

      hp = influxdb_client.Point("system").field("cost", cost).field("watts", hwatts)
      write_api.write(bucket=bucket, org=org, record=hp)
      logging.info(f'System total: {hwatts} watts, {cost} cost')

      for device in results['devices']:
        did = device.get('id')
        name = device.get('name')
        watts = device.get('w')
        location = device.get('location', 'NA')

        p = influxdb_client.Point("devices").tag("name", name).tag("location", location).tag("id", did).field("watts", watts)
        write_api.write(bucket=bucket, org=org, record=p)
        logging.info(f' => {name}({did}) - {location} - {watts}')
  except Exception as e:
    logging.error(f'Errored out with: {e}')
    logging.info(results)
    raise

read_realtime_metrics()
