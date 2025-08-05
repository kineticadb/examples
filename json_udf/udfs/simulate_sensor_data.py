from datetime import datetime, timezone
import random
import json
from kinetica_proc import ProcData

def generate_metric_value(sensor_type):
    if sensor_type == "temperature":
        return round(random.uniform(65, 85), 1)
    elif sensor_type == "humidity":
        return round(random.uniform(35, 65), 1)
    elif sensor_type == "voltage":
        return round(random.uniform(210, 240), 1)
    elif sensor_type == "vibration":
        return round(random.uniform(0.1, 0.9), 2)

def simulate_sensor_json(device_id='sensor-4390'):
    now = datetime.now(timezone.utc).isoformat(timespec='seconds')
    readings = []

    # Baseline readings
    temperature = generate_metric_value("temperature")
    humidity = generate_metric_value("humidity")
    voltage = generate_metric_value("voltage")
    vibration = generate_metric_value("vibration")

    readings.append({
        "scenario": "Baseline_Readings",
        "metrics": [
            {"type": "temperature", "value": temperature},
            {"type": "humidity", "value": humidity},
            {"type": "voltage", "value": voltage},
            {"type": "vibration", "value": vibration}
        ],
        "status": {
            "read_status": "OK",
            "read_error_type": "",
            "read_error_message": ""
        }
    })

    return {
        "device_id": device_id,
        "last_updated": now,
        "readings": readings
    }

if __name__ == '__main__':
    proc_data = ProcData()
    out_table = proc_data.output_data[0]

    params = proc_data.params
    device_id = params.get("device_id", "sensor-4390")

    # Prepare simulated row
    sensor_json = simulate_sensor_json(device_id)
    json_string = json.dumps(sensor_json)

    out_table.size = 1
    out_table[0].append(json_string)

    proc_data.complete()
