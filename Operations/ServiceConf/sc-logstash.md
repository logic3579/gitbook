```bash
# logstash.conf
# input config
input {
    # filebeat plugin
    beats {
	    port => 5044
    }
    # http plugin
    http {
	    host => "0.0.0.0"
	    port => 5999
	    additional_codecs => {"application/json"=>"json"}
	    codec => json {charset=>"UTF-8"}
	    ssl => false
	}
}
# filter config
filter {
    ruby {
        code => "
            event.set('local_time' , Time.now.strftime('%Y-%m-%d'))
            event.set('backup_time' , Time.now.strftime('%Y-%m-%d'))
        "
    }

    if [agent][type] == "filebeat" {
        mutate { update => { "host" => '%{[agent][name]}' }}
        mutate { replace => { "source" => '%{[log][file][path]}' }}
    }
    else if [user_agent][original] == "Fluent-Bit" {
      json {
        source => "message"
      }
      mutate {
        add_field => { "index_name" => "%{[kubernetes_container_name]}" }
      }
      mutate {
        gsub => ["[index_name]", "-", "_"]
      }
    }
}
# output config
output {
    # stdout { codec => rubydebug } #Used to validate/troubleshoot

    # backup to file
    if [user_agent][original] == "Fluent-Bit" {
      file {
          path => "/opt/backup_logs/%{backup_time}/%{host_ip}_%{index_name}/%{index_name}.gz"
          gzip => true
          codec =>  line {
              format => "[%{index_name} -->| %{message}"
              }
          }
    }
    if [agent][type] == "filebeat" {
      file {
        path => "/opt/all_logs/%{local_time}/%{[host]}/%{[source]}.gz"
        gzip => true
        codec =>  line {
            format => "[%{[host]} -- %{[source]}] -->| %{message}"
            }
        }
    }
    
    # send to elasticsearch
    if [host_ip] == "xxx" and [namespace_name] == "default" {
      elasticsearch {
        hosts => ["http://es_server_1:9200"]
        user => elastic
        password => "es123"
        index => "logstash-uat_%{index_name}-%{local_time}"
      }
    
    }
    else if [host_ip] == "xxx" and [namespace_name] == "default"  {
     elasticsearch {
       hosts => ["http://es_server_2:9200"]
       user => elastic
       password => "es123"
       index => "logstash-%{index_name}-%{local_time}"
     }
   } 
}

```