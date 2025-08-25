from flask import Flask, jsonify
import os
import psycopg2

app = Flask(__name__)

@app.get("/health")
def health():
    return {"ok": True}

@app.get("/db-check")
def db_check():
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST","localhost"),
            dbname=os.getenv("DB_NAME","appdb"),
            user=os.getenv("DB_USER","appuser"),
            password=os.getenv("DB_PASSWORD","apppass"),
            port=int(os.getenv("DB_PORT","5432"))
        )
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
            return jsonify({"db": "reachable"}), 200
    except Exception as e:
        return jsonify({"db": "error", "msg": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT","5000")))
