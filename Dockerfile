FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y python3 python3-dev python3-pip

COPY ./SamplePythonApps/requirements.txt /app/requirements.txt

WORKDIR /app

RUN apt-get -y update

RUN pip3 install -r requirements.txt

COPY /SamplePythonApps/. /app

EXPOSE 5000

ENTRYPOINT ["/usr/bin/python3"]

CMD ["main.py"]