### PUSH NEW CODE/UPDATES HERE
### git pull etc
/usr/local/bin/php -dmemory_limit=8000M bin/magento setup:upgrade;
/usr/local/bin/php -dmemory_limit=8000M bin/magento setup:di:compile;
/usr/local/bin/php -dmemory_limit=8000M /usr/local/bin/composer dump-autoload --no-dev --optimize --apcu;
/usr/local/bin/php -dmemory_limit=8000M bin/magento setup:static-content:deploy --jobs=$(nproc);
/usr/share/stratus/cli zerodowntime.init;
/usr/share/stratus/cli zerdowntime.switch;
echo "\e[41m****Flushing Magento, Varnish, Redis and CloudFront CDN cache at this stage****";
/usr/local/bin/php -dmemory_limit=8000M bin/magento cache:clean;
/usr/local/bin/php -dmemory_limit=8000M bin/magento cache:flush;
/usr/share/stratus/cli cache.cloudfront.invalidate
/usr/share/stratus/cli cache.varnish.clear;
redis-cli -h redis flushall && redis-cli -h redis-config-cache -p 6381 flushall;
echo "\e[41m****Deployment Finished Site Enabled and tested****";
status_code=$(curl -kI --header 'Host: {yourhost}.com' --write-out %{http_code} --silent --output /dev/null 'https://nginx/')
if [[ "$status_code" -ne 200 ]] ; then
  echo "Site not active $status_code please push script again"
else
  echo "\e[41m****Beginning Indexing****";
n98-magerun2 sys:cron:run indexer_reindex_all_invalid;
n98-magerun2 sys:cron:run indexer_update_all_views;
