import flask
from flask import jsonify
import socket
from datetime import datetime
from flask.templating import render_template
import os
import threading
import logging 
from opencensus.ext.azure.log_exporter import AzureEventHandler
import time


app=flask.Flask(__name__)
app.config["DEBUG"] = True

## Get Environmental Variables
host_name = socket.gethostname()
host_ip = socket.gethostbyname(host_name)
app_insight_key = os.environ.get('APP_INSIGHT_KEY')

## Heartbeat function to send logs to Azure
def heartbeat_function():
    logger = logging.getLogger(__name__)
    logger.addHandler(AzureEventHandler(connection_string=app_insight_key))
    logger.setLevel(logging.INFO)
    while True:
        logger.info("Host Name: %s, IP Address: %s is running" % (host_name, host_ip))
        time.sleep(30)

## Homepage
@app.route('/',methods=['GET'])
def home():
    return render_template('index.html',hostname=host_name,hostip=host_ip)

## Dynamic return
@app.route('/api/time',methods=['GET'])
def getTime():
        return(jsonify(timestamp=datetime.now()))

## Handle Error
@app.errorhandler(404)
def page_not_found(e):
        return render_template('error.html')

## Main Function
if __name__ == "__main__":
    x = threading.Thread(target=heartbeat_function)
    x.start()
    app.run(host='0.0.0.0', port=5000)