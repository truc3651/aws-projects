docker run -it --rm \
    --name filebeat \
    --network elastic \
  -v $(pwd)/filebeat.yaml:/usr/share/filebeat/filebeat.yml \
  -v $(pwd)/logstash-tutorial.log:/usr/share/filebeat/logstash-tutorial.log \
  docker.elastic.co/beats/filebeat:8.17.3 \
  -c /usr/share/filebeat/filebeat.yml \
  -d "publish"

docker run -it --rm \
    --name logstash \
    --network elastic \
    -p 5044:5044 \
    -v $(pwd)/logstash.conf:/config/logstash.conf \
    docker.elastic.co/logstash/logstash:8.17.3 \
    -f /config/logstash.conf \
    --config.reload.automatic

docker run -it --rm \
  --name elasticsearch \
  --network elastic \
  -p 9200:9200 \
  -p 9300:9300 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
  docker.elastic.co/elasticsearch/elasticsearch:8.17.3
