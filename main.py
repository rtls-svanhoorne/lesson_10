# create a fastapi application that will return a nice bootstrap page from results of the database
# showing the results of wines of the world in a nice table
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
import sqlite3
from os import path

app = FastAPI()
templates = Jinja2Templates(directory="templates")
current_dir = path.dirname(path.realpath(__file__))
parent_dir = path.dirname(current_dir)
sql_file = path.join(parent_dir, "complex.sql")
db_file = path.join(parent_dir, "ratings.db")


@app.get("/", response_class=HTMLResponse)
async def read_wines(request: Request):
    return templates.TemplateResponse("index.j2", {"request": request})


@app.get("/api/ratings")
async def get_ratings(request: Request):
    # Read the SQL query from the file
    with open(sql_file, "r") as file:
        query = file.read()
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()

    cursor.execute(query)
    results = cursor.fetchall()
    conn.close()

    # Convert results to a list of dictionaries
    keys = ["name", "region", "variety", "wine_year", "rating", "rolling_avg_rating", "performance_ratio", "performance_trend", "rating_category"]
    results_dict = [dict(zip(keys, row)) for row in results]

    return {"results": results_dict}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0")
