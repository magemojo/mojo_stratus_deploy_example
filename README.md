# Mojo Stratus Deploy Example
Recommended Bash script for Magento 2 deployments on MojoStratus Platform

## Commands

> Maintenance mode is needed for now because the reinit command will split brain php-fpm code until all complete. A fix for this is being actively worked on will be released soon.
```bash
php bin/magento maintenance:enable;
```

> If you enabled one or more modules, then you will need to run magento setup:upgrade to update the database schema. By default, magento setup:upgrade clears compiled code and the cache. Typically, you use magento setup:upgrade to update components and each component can require different compiled classes.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento setup:upgrade;
```

> The command setup:di:compile command generates the contents of the var/di folder in Magento <2.2 and generated for Magento >= 2.2 and 2.3+. According to the Magento docs this is more an optimization step (that is, optimized code generation of interceptors). It's not mandatory to run setup:di:compile command everytime but if you have done any code change specially with factory methods ,proxy, add plugins or any code compilation then you must need to run this command.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento setup:di:compile;
```

> This is the command you'd run before deploying to production mode. If you're running in default or developer mode, those files should be generating for your automatically. Magento 2 requires deployment of static assets such as CSS/JS based on your theme.  Deploy via your panel using these steps.  This may take some time to complete.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento setup:static-content:deploy --jobs=$(nproc);
```

> If you have autoscaling enabled, this command will issue a redeploy of PHP-FPM services and update code copied out to the various physical nodes. This is a rolling redeploy for zero instance downtime & minimal site downtime. The command executes asynchronously and will return before all the redeploy is completed. PLEASE NOTE: On average a redeploy takes several seconds & depends on the size of your code base.
```bash
/usr/share/stratus/cli autoscaling.reinit;
```

> We have added additional wait process to make sure scaled php-fpm pods are reinstated and fully functional
```bash
sleep 150s;
```

> Short description of cache invalidate/flush commands pushed in next block
```bash
echo "\e[41m****Flushing Magento, Varnish, Redis and CloudFront CDN cache at this stage****";
```

> Cleaning a cache type deletes all items from enabled Magento cache types only. In other words, this option does not affect other processes or applications because it cleans only the cache that Magento uses.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento cache:clean;
```

> Flushing a cache type purges the cache storage, which might affect other processes applications that are using the same storage.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento cache:flush;
```

> Clears Cloudfront CDN cache only. This can take up to 15 minutes.
```bash
/usr/share/stratus/cli cache.cloudfront.invalidate
```

> This command purges Varnish cache entirely.
```bash
/usr/share/stratus/cli cache.varnish.clear;
```

> This line purges Redis Page and Full Page cache (if Varnish not used).
```bash
redis-cli -h redis flushall && redis-cli -h redis-config-cache -p 6381 flushall;
```

> Disable maintenance mode command.
```bash
php bin/magento maintenance:disable;
```

> Description message that deployment is being done and that certain testing starts.
```bash
echo "\e[41m****Deployment Finished Site Enabled and tested****";
```

> In next block we will test using CURL method if store is actually giving 200 OK response or not. Area that needs to be adjusted is Host: with real domain name used.
```bash
status_code=$(curl -kI --header 'Host: cbi2cs52sas1djs9.mojostratus.io' --write-out %{http_code} --silent --output /dev/null 'https://nginx/')
```

> Two type of responces expected, either echo that task is completed or message that something went wrong and needs investigated.
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
