from flask import Flask, jsonify
import boto3
import json
import os
from sqlalchemy import create_engine, text

app = Flask(__name__)

# Retrieve secrets
client = boto3.client('secretsmanager', region_name=os.environ['AWS_REGION'])
response = client.get_secret_value(SecretId=os.environ['SECRET_ARN'])
secrets = json.loads(response['SecretString'])

# Database connection
engine = create_engine(f"postgresql://admin:{secrets['DB_PASSWORD']}@{os.environ['RDS_ENDPOINT']}/postgres")

@app.route('/')
def home():
    return "Hello, World!"

@app.route('/health')
def health():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        return "OK", 200
    except Exception as e:
        return str(e), 500

@app.route('/data')
def data():
    try:
        with engine.connect() as connection:
            result = connection.execute(text("SELECT * FROM items LIMIT 10"))
            items = [row['name'] for row in result]
        return jsonify(items), 200
    except Exception as e:
        return str(e), 500

@app.route('/api_status')
def api_status():
    return "API key retrieved successfully" if 'API_KEY' in secrets else "API key not found", 200 if 'API_KEY' in secrets else 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)