import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from psycopg import connect
from psycopg.rows import dict_row

app = FastAPI(title="Electro API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _build_dsn() -> str:
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return database_url

    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")
    name = os.getenv("DB_NAME", "electrodb")
    user = os.getenv("DB_USER", "electro")
    password = os.getenv("DB_PASSWORD", "electro")
    return f"postgresql://{user}:{password}@{host}:{port}/{name}"


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/hello")
def hello() -> dict:
    return {"message": "Hello from Electro backend"}


@app.get("/db-check")
def db_check() -> dict:
    dsn = _build_dsn()
    try:
        with connect(dsn, row_factory=dict_row, connect_timeout=3) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1 AS ok")
                result = cur.fetchone() or {"ok": 0}
        return {"database": "reachable", "result": result}
    except Exception as exc:
        return {"database": "unreachable", "error": str(exc)}
