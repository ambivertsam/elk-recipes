['java-1.7.0-openjdk', 'elasticsearch', 'logstash', 'kibana', 'filebeat'].each do |pkg|
  describe package(pkg) do
    it {should be_installed}
  end
end
