# Mojo Stratus Deploy Example

## Recommended Bash script for Magento 2 deployments on MojoStratus Platform

> Maintenance mode is needed for now because the reinit command will split brain php-fpm code until all complete. A fix for this is being actively worked on will be released soon.
```bash
time php bin/magento maintenance:enable;
```

> [needs description]
```bash
time /usr/local/bin/php -dmemory_limit=20000M bin/magento setup:upgrade;
```

> [needs description]
```bash
time /usr/local/bin/php -dmemory_limit=20000M bin/magento setup:di:compile;
```

> [needs description]
```bash
time /usr/local/bin/php -dmemory_limit=20000M bin/magento setup:static-content:deploy --jobs=$(nproc);
```

> [needs description]
```bash
/usr/share/stratus/cli autoscaling.reinit;
```

> [needs description]
```bash
sleep 150s;
```

> [needs description]
```bash
echo "\e[41m****Flushing Magento, Varnish, Redis and CloudFront CDN cache at this stage****";
```

> [needs description]
```bash
time /usr/local/bin/php -dmemory_limit=20000M bin/magento cache:clean;
```

> [needs description]
```bash
time /usr/local/bin/php -dmemory_limit=20000M bin/magento cache:flush;
```

> [needs description]
```bash
time /usr/share/stratus/cli cache.cloudfront.invalidate
```

> [needs description]
```bash
/usr/share/stratus/cli cache.varnish.clear;
```

> [needs description]
```bash
redis-cli -h redis flushall && redis-cli -h redis-config-cache -p 6381 flushall;
```

> [needs description]
```bash
time php bin/magento maintenance:disable;
```

> [needs description]
```bash
echo "\e[41m****Deployment Finished Site Enabled and tested****";
```

> [needs description]
```bash
status_code=$(curl -kI --header 'Host: cbi2cs52sas1djs9.mojostratus.io' --write-out %{http_code} --silent --output /dev/null 'https://nginx/')
```

> [needs description]
```bash
if [[ "$status_code" -ne 200 ]] ; then
  echo "Site not active $status_code please push script again"
else
  echo "\e[41m****Beginning Indexing****";
  n98-magerun2 sys:cron:run indexer_reindex_all_invalid;
  n98-magerun2 sys:cron:run indexer_update_all_views;
  echo "\e[41m****Activity Completed please visit store and test****";
fi
```
