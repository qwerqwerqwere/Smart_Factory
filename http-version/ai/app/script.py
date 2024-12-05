from influxdb_client import InfluxDBClient, Point
import joblib
import time


load_dotenv(dotenv_path="~/projects/Rabbitmq-Grafana/docker/credentials.env")
# 환경 변수에서 InfluxDB 설정 가져오기
import os
INFLUXDB_URL = "http://localhost:8086"
TOKEN = os.getenv("DOCKER_INFLUXDB_INIT_ADMIN_TOKEN")
ORG = os.getenv("DOCKER_INFLUXDB_INIT_ORG")
BUCKET = os.getenv("DOCKER_INFLUXDB_INIT_BUCKET")

# InfluxDB 클라이언트 초기화
client = InfluxDBClient(url=INFLUXDB_URL, token=TOKEN, org=ORG)
query_api = client.query_api()
write_api = client.write_api()

# 모델 로드
model_path = "/app/model.pkl"  # 컨테이너 내부 경로
model = joblib.load(model_path)

# InfluxDB 쿼리 가져올field 확인필요
query = f"""
from(bucket: "{BUCKET}")
|> range(start: -10s)
|> filter(fn: (r) => r._measurement == "machine_status")
|> filter(fn: (r) => r._field == "value")
"""

def fetch_data():
    """InfluxDB에서 데이터를 가져오는 함수"""
    tables = query_api.query(query)
    data = []
    for table in tables:
        for record in table.records:
            data.append(record.get_value())
    return data

def predict_and_store():
    """데이터를 예측하고 결과를 저장"""
    while True:
        data = fetch_data()
        if not data:
            print("No data found. Waiting...")
            time.sleep(1)
            continue
        
        # 모델 예측
        input_data = [data]
        prediction = model.predict(input_data)[0]
        
        # 예측 결과 저장
        point = Point("predicted_data").field("prediction", float(prediction))
        write_api.write(bucket=BUCKET, org=ORG, record=point)
        print(f"Prediction: {prediction}")

        time.sleep(1)

if __name__ == "__main__":
    predict_and_store()
