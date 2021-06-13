import os
from types import MethodType
import flask
from flask import request, jsonify
import json
from datetime import datetime
import socket
import threading
import logging 
from opencensus.ext.azure.log_exporter import AzureEventHandler
import time

app = flask.Flask(__name__)
app.config["DEBUG"] = False
host_name = socket.gethostname()
host_ip = socket.gethostbyname(host_name)
app_insight_key = os.environ.get('APP_INSIGHT_KEY')

def heartbeat_function():
    logger = logging.getLogger(__name__)
    logger.addHandler(AzureEventHandler(connection_string=app_insight_key))
    logger.setLevel(logging.INFO)
    while True:
        logger.info("Host Name: %s, IP Address: %s is running" % (host_name, host_ip))
        time.sleep(30)

#Main page
@app.route('/',methods=['GET'])
def home():
    try:
        returnText = "Host Name: %s, IP Address: %s" % (host_name, host_ip)
        return "<h1>Home</h1><p>%s<p>" %returnText
    except:
        return "<h1>Api App</h1><p>The app is running.<p>"

@app.route('/api/time',methods=['GET'])
def currentTime():
    return(jsonify(timestamp=datetime.now()))
    
@app.errorhandler(404)
def page_not_found(e):
    return "<h1>404</h1><p>The resource could not be found.</p>", 404

if __name__ == "__main__":
    x = threading.Thread(target=heartbeat_function)
    x.start()
    app.run(host='0.0.0.0', port=5000)