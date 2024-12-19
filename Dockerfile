FROM python:alpine

ARG LOG_LEVEL=1

ENV LOG_LEVEL=${LOG_LEVEL}

RUN apk update && apk add --no-cache bash sqlite curl dcron tini

VOLUME /data

WORKDIR /app

COPY ./src .

RUN chmod +x main.py
RUN pip install --no-cache-dir -r requirements.txt

RUN echo '0 * * * * /app/main.py >> /proc/1/fd/1 2>&1' > /etc/crontabs/root

ENTRYPOINT ["/sbin/tini", "--", "sh", "-c", "crond -f -l ${LOG_LEVEL}"]
