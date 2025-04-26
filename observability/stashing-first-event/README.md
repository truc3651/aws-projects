docker run -it --rm -v $(pwd)/logstash-test.conf:/config/logstash-test.conf docker.elastic.co/logstash/logstash:8.11.3 -f /config/logstash-test.conf
