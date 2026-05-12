FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    python3.10 python3.11 python3-pip git virtualenv \
    && pip3 install virtualenvwrapper

ENV WORKON_HOME=/root/.virtualenvs
RUN mkdir -p $WORKON_HOME

COPY . /opt/bootstrap
RUN /opt/bootstrap/baseenv_setup.sh 3.10

ENTRYPOINT ["bash"]
