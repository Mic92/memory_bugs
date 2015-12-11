


args = {
  hosts: hosts,
  logger: logger,
  retry_on_failure: 5,
  reload_connections: true
}
$elasticsearch = Elasticsearch::Client.new(**args)
