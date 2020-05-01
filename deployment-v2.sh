time php bin/magento maintenance:enable;
#n98-magerun2 cache:disable;
#php bin/magento cache:flush;
#/usr/share/stratus/cli cache.all.clear;
time /usr/local/bin/php -dmemory_limit=20000M bin/magento setup:upgrade;
time /usr/local/bin/php -dmemory_limit=20000M bin/magento setup:di:compile;
time /usr/local/bin/php -dmemory_limit=20000M bin/magento setup:static-content:deploy --jobs=$(nproc);
#php bin/magento setup:static-content:deploy -f -j 10;
#php bin/magento indexer:reindex;
#n98-magerun2 cache:enable;
/usr/share/stratus/cli autoscaling.reinit;
sleep 200s;
time /usr/local/bin/php -dmemory_limit=20000M bin/magento cache:clean;
time /usr/local/bin/php -dmemory_limit=20000M bin/magento cache:flush;
#/usr/share/stratus/cli cache.all.clear;  -- changed to /usr/share/stratus/cli cache.cloudfront.invalidate since php-fpm pods are already nuked so waste of time to do this call.
time /usr/share/stratus/cli cache.cloudfront.invalidate
time php bin/magento maintenance:disable;
echo "\e[41m****Deployment Finished Site Enabled****";
echo "\e[41m****Beginning Indexing****";
/usr/local/bin/php -dmemory_limit=20000M bin/magento indexer:reindex;
echo "\e[41m****Flushing Varnish and Redis at this stage****";
#/usr/share/stratus/cli cache.all.clear; -- No need to do that again fresh php-fpm pods are already active
/usr/share/stratus/cli cache.varnish.clear;
redis-cli -h redis flushall && redis-cli -h redis-config-cache -p 6381 flushall;

echo "\e[41m****Activity Completed please visit store and test****";
