FROM php:8.0-cli

RUN apt-get update
RUN apt-get install -y jq
RUN apt-get install -y git zip
RUN apt-get install -y python3
RUN apt-get install -y python3-requests

COPY entrypoint.sh \
     phpdoctor-matcher.json \
     parse_phpdoctor.py \
     /action/
COPY phpdoctor.phar /usr/local/bin/phpdoctor

RUN chmod +x /action/entrypoint.sh
RUN chmod +x /action/parse_phpdoctor.py

ENTRYPOINT ["/action/entrypoint.sh"]
