/etc/td-agent/td-agent.conf
```bash
<system>
  workers 4
</system>

# for filebeat logs of opt,var,etc..
# /opt/td-agent/bin/gem install fluent-plugin-beats --no-document 
<worker 0>
  <source>
    @type beats
    port 5044
    metadata_as_tag
    @label @filebeat_logs
  </source>
</worker>

# for uat application logs
<worker 1>
  <source>
    @type forward
    port 24224
    @label @uat_logs
  </source>
</worker>

# for prod application logs
<worker 2-3>
  <source>
    @type forward
    port 24225
    @label @prod_logs
  </source>
</worker>

#########

<label @filebeat_logs>
  <filter *beat>
    @type record_transformer
    enable_ruby true

    <record>
      log_path ${record["log"]["file"]["path"]}
    </record>
  </filter>

  <match *beat>
    <format>
      @type single_value
      message_key message
    </format>

    @type file
    path /opt/backup_logs/%Y-%m-%d/${$.log_path}
    append true
    add_path_suffix false
    compress gzip

    <buffer time,$.log_path>
      @type file
      path /tmp/beat/%Y-%m-%d/${$.log_path}
      timekey 1d
      timekey_wait 10s
      timekey_use_utc true

      flush_at_shutdown true
      flush_mode interval
      flush_interval 10s
    </buffer>
  </match>
</label>

<label @uat_logs>
  <filter kube.**>
    @type record_transformer
    remove_keys time,stream,_p,host,kubernetes_namespace_name,kubernetes_pod_id,kubernetes_docker_id,kubernetes_container_hash,kubernetes_container_image,kubernetes_pod_name,kubernetes_host,host_ip

    <record>
      log_path ${record["host_ip"]}_${record["kubernetes_container_name"]}
    </record>
  </filter>

  <match kube.**>
    <format>
      @type single_value
      message_key message
      #@type out_file
      #output_tag false
      #output_time false
    </format>

    #@type stdout
    @type file
    path /opt/backup_logs/uat/%Y-%m-%d/${$.log_path}/${$.kubernetes_container_name}
    # flushed chunk appended to one file
    append true
    compress gzip

    # <buffer tag,time>
    <buffer time,$.log_path,$.kubernetes_container_name>
      @type file
      timekey 1d
      timekey_wait 10s
      timekey_use_utc true
      flush_at_shutdown true
      flush_mode interval
      flush_interval 10s
    </buffer>
  </match>
</label>

<label @prod_logs>
  <filter kube.**>
    @type record_transformer
    remove_keys time,stream,_p,host,kubernetes_namespace_name,kubernetes_pod_id,kubernetes_docker_id,kubernetes_container_hash,kubernetes_container_image,kubernetes_pod_name,kubernetes_host,host_ip,es_index,local_time

    <record>
      log_path ${record["host_ip"]}_${record["kubernetes_container_name"]}
    </record>
  </filter>

  <match kube.**>
    <format>
      @type single_value
      message_key message
    </format>

    @type file
    path /opt/backup_logs/prod/%Y-%m-%d/${$.log_path}/${$.kubernetes_container_name}
    append true
    compress gzip
    
    <buffer time,$.log_path,$.kubernetes_container_name>
      @type file
      timekey 1d
      timekey_wait 10s
      timekey_use_utc true
      flush_at_shutdown true
      flush_mode interval
      flush_interval 10s
    </buffer>
  </match>
</label>

```