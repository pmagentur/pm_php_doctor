FROM php:7.4-cli

RUN apt-get update
RUN apt-get install -y jq
# RUN apt-get install -y git zip

COPY entrypoint.sh \
     phpdoctor-matcher.json \
     /action/
COPY phpdoctor.phar /usr/local/bin/phpdoctor

RUN chmod +x /action/entrypoint.sh

ENTRYPOINT ["/action/entrypoint.sh"]
