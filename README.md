# Mojo Stratus Deploy Example
Recommended Bash script for Magento 2 deployments on MojoStratus Platform

```
time php bin/magento maintenance:enable;
```

```
time /usr/local/bin/php -dmemory_limit=20000M bin/magento setup:upgrade;
```

```
time /usr/local/bin/php -dmemory_limit=20000M bin/magento setup:di:compile;
```

```
time /usr/local/bin/php -dmemory_limit=20000M bin/magento setup:static-content:deploy --jobs=$(nproc);
```

```
/usr/share/stratus/cli autoscaling.reinit;
```

```
sleep 150s;
```

```
echo "\e[41m****Flushing Magento, Varnish, Redis and CloudFront CDN cache at this stage****";
```

```
time /usr/local/bin/php -dmemory_limit=20000M bin/magento cache:clean;
```

```
time /usr/local/bin/php -dmemory_limit=20000M bin/magento cache:flush;
```

```
time /usr/share/stratus/cli cache.cloudfront.invalidate
```

```
/usr/share/stratus/cli cache.varnish.clear;
```

```
redis-cli -h redis flushall && redis-cli -h redis-config-cache -p 6381 flushall;
```

```
time php bin/magento maintenance:disable;
```

```
echo "\e[41m****Deployment Finished Site Enabled and tested****";
```

```
status_code=$(curl -kI --header 'Host: cbi2cs52sas1djs9.mojostratus.io' --write-out %{http_code} --silent --output /dev/null 'https://nginx/')
```

```
if [[ "$status_code" -ne 200 ]] ; then
  echo "Site not active $status_code please push script again"
else
  echo "\e[41m****Beginning Indexing****";
  n98-magerun2 sys:cron:run indexer_reindex_all_invalid;
  n98-magerun2 sys:cron:run indexer_update_all_views;
  echo "\e[41m****Activity Completed please visit store and test****";
fi
```
