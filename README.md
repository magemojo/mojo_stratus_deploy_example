# Mojo Stratus Zero Downtime Deploy Example
Recommended Bash script for Magento 2 deployments on Mojo Stratus Platform using Zero Downtime strategy. ZDD feature must be enabled from Stratus panel --> Autoscaling area in order to be used. <BR>
Kb: https://magemojo.com/kb/best-practices/zero-downtime-deploys/ <BR>
filename: deploy-zdd.sh <BR>

For old deployment example navigate down or click https://github.com/magemojo/mojo_stratus_deploy_example/blob/master/README.md#mojo-stratus-deploy-example here.

## Commands
> Stop crons
```
/usr/share/stratus/cli crons.stop;
```

> If you enabled one or more modules, then you will need to run magento setup:upgrade to update the database schema. By default, magento setup:upgrade clears compiled code and the cache. Typically, you use magento setup:upgrade to update components and each component can require different compiled classes.
```bash
/usr/local/bin/php -dmemory_limit=8000M bin/magento setup:upgrade;
```
To prevent generated files from being deleted, please update command with --keep-generated flag

> The command setup:di:compile command generates the contents of the var/di folder in Magento <2.2 and generated for Magento >= 2.2 and 2.3+. According to the Magento docs this is more an optimization step (that is, optimized code generation of interceptors). It's not mandatory to run setup:di:compile command everytime but if you have done any code change specially with factory methods, proxy, add plugins or any code compilation then you must need to run this command.
```bash
/usr/local/bin/php -dmemory_limit=8000M bin/magento setup:di:compile;
```

> The class loader used while developing the application is optimized to find new and changed classes. In production servers, PHP files should never change, unless a new application version is deployed. That's why you can optimize Composer's autoloader to scan the entire application once and build a "class map", which is a big array of the locations of all the classes and it's stored in vendor/composer/autoload_classmap.php.
```bash
/usr/local/bin/php -dmemory_limit=8000M /usr/local/bin/composer dump-autoload --no-dev --optimize --apcu;
```

> This is the command you'd run before deploying to production mode. If you're running in default or developer mode, those files should be generating for you automatically. Magento 2 requires deployment of static assets such as CSS/JS based on your theme.  Deploy via your panel using these steps.  This may take some time to complete.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento setup:static-content:deploy --jobs=$(nproc);
```

> The init command creates additional PHP-FPM containers with your current code base. When you call the switch command, Nginx is updated to point to the new containers, and the old containers are gracefully terminated. Any remaining connections are allowed to complete on the older codebase. During the init stage, the code you see within the SSH shell or over SFTP is not live, other than files in directories marked as Shared in the autoscaling configuration. Autoscaling and the init phase copy your code to the PHP-FPM containers directly separate from what you see via SSH. 
```bash
/usr/share/stratus/cli zerodowntime.init;
```

> Run the switch command to switch over to the new code base
```bash
/usr/share/stratus/cli zerodowntime.switch;
```

> Short description of cache invalidate/flush commands pushed in next block.
```bash
echo "\e[41m****Flushing Magento, Varnish, Redis and CloudFront CDN cache at this stage****";
```

> Cleaning a cache type deletes all items from enabled Magento cache types only. In other words, this option does not affect other processes or applications because it cleans only the cache that Magento uses. Magento 2.4.2 users can remove cache:clean from their deployment scripts since latest setup:upgrade flushes caches when executed.
```bash
/usr/local/bin/php -dmemory_limit=8000M bin/magento cache:clean;
```

> Flushing a cache type purges the cache storage, which might affect other processes applications that are using the same storage. Magento 2.4.2 users can remove cache:flush from their deployment scripts since latest setup:upgrade flushes caches when executed.
```bash
/usr/local/bin/php -dmemory_limit=8000M bin/magento cache:flush;
```

> Flushes only the PHP OpCache.
```bash
/usr/share/stratus/cli cache.opcache.flush;
```
  
> Clears Cloudfront CDN cache only. This can take up to 15 minutes.
```bash
/usr/share/stratus/cli cache.cloudfront.invalidate;
```

> This command purges Varnish cache entirely.
```bash
/usr/share/stratus/cli cache.varnish.clear;
```

> This line purges Redis Page and Full Page cache (if Varnish not used). The Redis Session instance is not flushed.
```bash
redis-cli -h redis flushall && redis-cli -h redis-config-cache -p 6381 flushall;
```

> Description message that deployment is being done and that certain testing starts.
```bash
echo "\e[41m****Deployment Finished Site Enabled and tested****";
```

> In next block we will test using CURL method if store is actually giving 200 OK response or not. This also warms caches. 

> **Host: needs your real domain name**.
```bash
status_code=$(curl -kI --header 'Host: cbi2cs52sas1djs9.mojostratus.io' --write-out %{http_code} --silent --output /dev/null 'https://nginx/')
```

> Two type of responses expected, either echo that task is completed or message that something went wrong and needs investigated. We will execute two Magento 2 cron tasks to Reindex all Invalid indexers and updated all views. Also, we will start Cron container and Cron tasks defined in the Stratus panel.
```bash
if [[ "$status_code" -ne 200 ]] ; then
  echo "Site not active $status_code please push script again"
else
  echo "\e[41m****Beginning Indexing****";
  n98-magerun2 sys:cron:run indexer_reindex_all_invalid;
  n98-magerun2 sys:cron:run indexer_update_all_views;
  /usr/share/stratus/cli crons.start;
  
  echo "\e[41m****Activity Completed please visit store and test****";
fi
/usr/local/bin/php -dmemory_limit=20000M bin/magento cache:clean;
```

> Flushing a cache type purges the cache storage, which might affect other processes applications that are using the same storage.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento cache:flush;
```

> Clears Cloudfront CDN cache only. This can take up to 15 minutes.
```bash
/usr/share/stratus/cli cache.cloudfront.invalidate;
```

> This command purges Varnish cache entirely.
```bash
/usr/share/stratus/cli cache.varnish.clear;
```

> This line purges Redis Page and Full Page cache (if Varnish not used). The Redis Session instance is not flushed.
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

> In next block we will test using CURL method if store is actually giving 200 OK response or not. This also warms caches. 

> **Host: needs your real domain name**.
```bash
status_code=$(curl -kI --header 'Host: cbi2cs52sas1djs9.mojostratus.io' --write-out %{http_code} --silent --output /dev/null 'https://nginx/')
```

> Two type of responses expected, either echo that task is completed or message that something went wrong and needs investigated. We will execute two Magento 2 cron tasks to Reindex all Invalid indexers and updated all views. Also, we will start Cron container and Cron tasks defined in the Stratus panel.
```bash
if [[ "$status_code" -ne 200 ]] ; then
  echo "Site not active $status_code please push script again"
else
  echo "\e[41m****Beginning Indexing****";
  n98-magerun2 sys:cron:run indexer_reindex_all_invalid;
  n98-magerun2 sys:cron:run indexer_update_all_views;
  /usr/share/stratus/cli crons.start;
  
  echo "\e[41m****Activity Completed please visit store and test****";
fi
```

# Mojo Stratus Deploy Example
Recommended Bash script for Magento 2 deployments on Mojo Stratus Platform

## Commands

> Stop crons
```
/usr/share/stratus/cli crons.stop;
```

> Maintenance mode is needed for now because the reinit command will split brain php-fpm code until all complete. A fix for this is being actively worked on will be released soon.
```bash
php bin/magento maintenance:enable;
```

> If you enabled one or more modules, then you will need to run magento setup:upgrade to update the database schema. By default, magento setup:upgrade clears compiled code and the cache. Typically, you use magento setup:upgrade to update components and each component can require different compiled classes.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento setup:upgrade;
```

> The command setup:di:compile command generates the contents of the var/di folder in Magento <2.2 and generated for Magento >= 2.2 and 2.3+. According to the Magento docs this is more an optimization step (that is, optimized code generation of interceptors). It's not mandatory to run setup:di:compile command everytime but if you have done any code change specially with factory methods, proxy, add plugins or any code compilation then you must need to run this command.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento setup:di:compile;
```

> The class loader used while developing the application is optimized to find new and changed classes. In production servers, PHP files should never change, unless a new application version is deployed. That's why you can optimize Composer's autoloader to scan the entire application once and build a "class map", which is a big array of the locations of all the classes and it's stored in vendor/composer/autoload_classmap.php.
```bash
/usr/local/bin/php -dmemory_limit=20000M /usr/local/bin/composer dump-autoload --no-dev --optimize --apcu;
```

> This is the command you'd run before deploying to production mode. If you're running in default or developer mode, those files should be generating for you automatically. Magento 2 requires deployment of static assets such as CSS/JS based on your theme.  Deploy via your panel using these steps.  This may take some time to complete.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento setup:static-content:deploy --jobs=$(nproc);
```

> If you have autoscaling enabled, this command will issue a redeploy of PHP-FPM services and update code copied out to the various physical nodes. This is a rolling redeploy for zero instance downtime & minimal site downtime. The command executes asynchronously and will return before all the redeploy is completed. PLEASE NOTE: On average a redeploy takes several seconds & depends on the size of your code base.
```bash
/usr/share/stratus/cli autoscaling.reinit;
```

> We have added additional wait process to make sure scaled php-fpm pods are reinstated and fully functional after the reinit command. The reinit command runs async so the sleep is needed.  We are currently improving reinit for increased speed and notification of completition - for future release.
```bash
sleep 150s;
```

> Short description of cache invalidate/flush commands pushed in next block.
```bash
echo "\e[41m****Flushing Magento, Varnish, Redis and CloudFront CDN cache at this stage****";
```

> Cleaning a cache type deletes all items from enabled Magento cache types only. In other words, this option does not affect other processes or applications because it cleans only the cache that Magento uses. Magento 2.4.2 users can remove cache:clean from their deployment scripts since latest setup:upgrade flushes caches when executed.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento cache:clean;
```

> Flushing a cache type purges the cache storage, which might affect other processes applications that are using the same storage. Magento 2.4.2 users can remove cache:flush from their deployment scripts since latest setup:upgrade flushes caches when executed.
```bash
/usr/local/bin/php -dmemory_limit=20000M bin/magento cache:flush;
```

> Clears Cloudfront CDN cache only. This can take up to 15 minutes.
```bash
/usr/share/stratus/cli cache.cloudfront.invalidate;
```

> This command purges Varnish cache entirely.
```bash
/usr/share/stratus/cli cache.varnish.clear;
```

> This line purges Redis Page and Full Page cache (if Varnish not used). The Redis Session instance is not flushed.
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

> In next block we will test using CURL method if store is actually giving 200 OK response or not. This also warms caches. 

> **Host: needs your real domain name**.
```bash
status_code=$(curl -kI --header 'Host: cbi2cs52sas1djs9.mojostratus.io' --write-out %{http_code} --silent --output /dev/null 'https://nginx/')
```

> Two type of responses expected, either echo that task is completed or message that something went wrong and needs investigated. We will execute two Magento 2 cron tasks to Reindex all Invalid indexers and updated all views. Also, we will start Cron container and Cron tasks defined in the Stratus panel.
```bash
if [[ "$status_code" -ne 200 ]] ; then
  echo "Site not active $status_code please push script again"
else
  echo "\e[41m****Beginning Indexing****";
  n98-magerun2 sys:cron:run indexer_reindex_all_invalid;
  n98-magerun2 sys:cron:run indexer_update_all_views;
  /usr/share/stratus/cli crons.start;
  
  echo "\e[41m****Activity Completed please visit store and test****";
fi
```
