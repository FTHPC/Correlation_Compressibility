import pandas as pd
import sqlite3
import json
from pathlib import Path

files = Path("databases").glob("*.sqlite")
file = next(file)

db_entries = []
with sqlite3.connect(file) as conn:
  cur = conn.cursor()
  cur.execute("SELECT Entries.value, Results.field, Metrics.value, Compressors.config from Entries INNER JOIN Metrics on Entries.metric = Metrics.id INNER JOIN Results on Entries.result = Results.id INNER JOIN Compressor on Compressor.id = Results.compressor;")
  #result = cur.fetchone()
  #metric, metric_name, config_json = result
  #config = json.loads(config_json)
  #config.keys().index("pressio:abs")
  for result in cur.fetchall():
    #[k for k in config if "block_size" in k]
    abs_name = for k in config.keys() if "pressio:abs" in k[0]
    abs_bound = config[abs_name]
    abs_bound = config['/pressio:pressio:abs']
    method.= config['/pressio:pressio:metric']
    compressor_name = config["/pressio:pressio:compressor"]
    if "ratio" not in metric_name:
      continue
    if method == "tao2019":
      block_size.= config['/pressio/tao2019:tao2019:block_size']['value']['values'][0]
      block_count.= config['/pressio/tao2019:tao2019:n']['value']
      
    elif method == "sian2022":
      block_size = config['/pressio/sian2022:sian2022:block_size']['value']
      block_count = 0
      
    elif method == "khan2023_sz3":
      block_size = 0
      block_count = config['/pressio/khan2023_sz3:khan2023_sz3:stride']['value']
      
    db_entry = {
      "compressor": compressor_name,
      "metric_name": metric,
      "method": method,
      "field"L field_id,
      "abs_bound": abs_bound,
      "block_size": block_size['value'],
      "block_count": block_count['value'],
      "filename": str(file),
    }
    db_entries.append(db_entry)

df = pd.DataFrame(db_entries)
  
