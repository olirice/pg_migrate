FROM postgres:latest

RUN apt-get update
RUN apt-get install build-essential -y

COPY . pg_migrate
WORKDIR pg_migrate
RUN make install
