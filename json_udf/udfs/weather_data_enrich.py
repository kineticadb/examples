from datetime import datetime, timezone
import requests
from kinetica_proc import ProcData
import time

WEATHER_API_KEY = 'YOUR KEY'

def to_epoch_ms(dt):
    return int(dt.timestamp() * 1000)

def get_weather_data(latitude, longitude):
    try:
        url = f'https://api.openweathermap.org/data/2.5/weather?lat={latitude}&lon={longitude}&appid={WEATHER_API_KEY}'
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            return {
                "weather_temp_c": round(data['main']['temp'] - 273.15, 2),
                "weather_humidity": data['main']['humidity'],
                "weather_pressure": data['main']['pressure'],
                "wind_speed": data['wind']['speed'],
                "last_updated": datetime.utcfromtimestamp(data['dt'])
            }
    except Exception as e:
        print(f"Weather API error: {e}")
    return None

if __name__ == '__main__':
    proc_data = ProcData()   
    params = proc_data.params
    latitude = float(params["latitude"])
    longitude = float(params["longitude"])

    for out_table in proc_data.output_data:    
        # Prepare empty rows to hold valid output
        valid_rows = []
        
        weather = get_weather_data(latitude, longitude)
        
        if weather:
            # Append entire row as a tuple
            valid_rows.append((
                to_epoch_ms(weather["last_updated"]),
                latitude,
                longitude,
                weather["weather_temp_c"],
                weather["weather_humidity"],
                weather["weather_pressure"],
                weather["wind_speed"]
            ))

        # Set table size based on valid rows only
        out_table.size = len(valid_rows)

        # Fill each column from row-wise data
        for row in valid_rows:
            for col_idx, value in enumerate(row):
                out_table[col_idx].append(value)

    proc_data.complete()
