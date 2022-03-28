# To learn more about Custom Resources, see https://docs.chef.io/custom_resources.html

provides :install  
  action :create do

    package node['elk']['java'] do
      action :install
    end

    bash "importing rpm package manager" do
      code <<-EOH
        rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch
        cd /home/vagrant
        touch a
        EOH
        not_if { ::File.exist? '/home/vagrant/a' }
    end

    yum_repository node['elk']['esearch'] do
      baseurl 'http://packages.elastic.co/elasticsearch/2.x/centos'
      gpgcheck true
      gpgkey 'http://packages.elastic.co/GPG-KEY-elasticsearch'
      enabled true
      action :create
    end

    package node['elk']['esearch'] do
      action :install
    end

    service node['elk']['esearch'] do
      action [ :enable, :start]
    end

    bash "enabling firewall over port 9200" do
      code <<-EOH
        firewall-cmd --add-port=9200/tcpfirewall-cmd --add-port=9200/tcp --permanent
        cd /home/vagrant
        touch a1
      EOH
      not_if { ::File.exist? '/home/vagrant/a1' }
    end

    yum_repository node['elk']['log'] do
      baseurl 'http://packages.elasticsearch.org/logstash/2.2/centos'
      gpgcheck true
      gpgkey 'http://packages.elasticsearch.org/GPG-KEY-elasticsearch'
      enabled true
      action :create
    end

    package node['elk']['log'] do
      action :install
    end

    bash "configuring certificates" do
      code <<-EOH
        cd /etc/pki/tls
        openssl req -config /etc/pki/tls/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
      EOH
      not_if { ::File.exist? '/etc/pki/tls/openssl.cnf' }
    end

    bash "configuring /etc/logstash/conf.d/input.conf" do
      code <<-EOH
        cd /etc/logstash/conf.d
        cat >>input.conf
        input {
          beats {
            port => 5044
            ssl => true
            ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
            ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
    }
          }
     EOH
     not_if { ::File.exist? '/etc/logstash/conf.d/input.conf' }
   end

    bash "configuring /etc/logstash/conf.d/output.conf" do
      code <<-EOH
        cd /etc/logstash/conf.d
          cat >>output.conf
          output {
                     elasticsearch {
          hosts => ["localhost:9200"]
          sniffing => true
          manage_template => false
          index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
          document_type => "%{[@metadata][type]}"
           }
        }
      EOH
      not_if { ::File.exist? '/etc/logstash/conf.d/output.conf' }
    end

    bash "configuring /etc/logstash/conf.d/filter.conf" do
      code <<-EOH
        cd /etc/logstash/conf.d
          cat >>filter.conf
          filter {
          if [type] == "syslog" {
          grok {
          match => { "message" => "%{SYSLOGLINE}" }
          }

          date {  match => [ "timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
           }
         }
       }
      EOH
      not_if { ::File.exist? '/etc/logstash/conf.d/filter.conf' }
    end

    bash "verifying logstash configuration" do
      code <<-EOH
        service logstash configtest
        cd /home/vagrant
        touch a7
      EOH
      not_if { ::File.exist? '/home/vagrant/a7' }
    end

    service node['elk']['log'] do
      action [ :enable, :start]
    end

    bash "enabling firewall over port 5044" do
      code <<-EOH
        firewall-cmd --add-port=5044/tcp
        firewall-cmd --add-port=5044/tcp --permanent
        cd /home/vagrant
        touch a2
    EOH
    not_if { ::File.exist? '/home/vagrant/a2' }
  end

    yum_repository node['elk']['log'] do
      baseurl 'http://packages.elastic.co/kibana/4.4/centos'
      gpgcheck true
      gpgkey 'http://packages.elastic.co/GPG-KEY-elasticsearch'
      enabled true
      action :create
    end

    package node['elk']['kibana'] do
      action :install
    end

    service node['elk']['kibana'] do
      action [ :enable, :start]
    end

    bash "enabling firewall over port 5601" do
      code <<-EOH
        firewall-cmd --add-port=5601/tcp
        firewall-cmd --add-port=5601/tcp --permanent
        cd /home/vagrant
        touch a3
      EOH
      not_if { ::File.exist? '/home/vagrant/a3' }
    end

    yum_repository node['elk']['filebeat'] do
      baseurl 'https://packages.elastic.co/beats/yum/el/$basearch'
      gpgcheck true
      gpgkey 'https://packages.elastic.co/GPG-KEY-elasticsearch'
      enabled true
      action :create
    end

   package node['elk']['filebeat'] do
     action :install
   end

   service node['elk']['filebeat'] do
    action [ :enable, :start]
   end
   
   yum_repository 'metricbeat' do
      baseurl 'https://artifacts.elastic.co/packages/6.x/yum'
      gpgcheck true
      gpgkey 'https://artifacts.elastic.co/GPG-KEY-elasticsearch'
      enabled true
      action :create
    end

   package 'metricbeat' do
     action :install
   end

   service 'metricbeat' do
    action [ :enable, :start]
   end
 
end
