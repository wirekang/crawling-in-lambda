FROM lambci/lambda:python3.7

ENV PYTHONDONTWRITEBYTECODE=1
USER root

WORKDIR /var/task

COPY $LAYER_DIR/* /opt/
COPY src/* /var/task/