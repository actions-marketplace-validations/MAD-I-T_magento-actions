# magento-actions
Magento 2 CI/CD using github actions
tests - phpcs - build - deploy - ([gitlab-ci](https://github.com/MAD-I-T/magento-actions/tree/master/gitlab-deployer) supported)


<div align="center">
  <a href="https://www.youtube.com/watch?v=C-P-vA6aw34"><img src="https://user-images.githubusercontent.com/3765910/128611467-7fd3aa5a-6df1-4fe5-bfa3-23f01355999d.jpeg" alt="magento zero downtime in video"></a>
</div>

# usage

To use this action your git repository must respect similar scaffolding to the following (or you can use the [install action](#install-magento-action)):

```bash
├── .github
│   └── workflows # directory where the workflows are found, see below for an example of main.yml 
├── README.md 
└── magento # directory where you Magento source files should go
```

Full usage example using Magento official develop branch [here](https://github.com/seyuf/m2-dev-github-actions)
Don't forget to deploy your services on a container i.e (`container: ubuntu` below).

##### main.yml

Config Example when magento v2.4
 ```
 name: m2-actions-test
 on: [push]
 
 jobs:
   magento2-build:
     runs-on: ubuntu-latest
     container: ubuntu
     name: 'm2 unit tests & build'
     services:
       mysql:
         image: docker://mysql:8.0
         env:
           MYSQL_ROOT_PASSWORD: magento
           MYSQL_DATABASE: magento
         ports:
           - 3306:3306
         options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
       elasticsearch:
         image: docker://elasticsearch:7.1.0
         ports:
           - 9200:9200
         options: -e="discovery.type=single-node" --health-cmd="curl http://localhost:9200/_cluster/health" --health-interval=10s --health-timeout=5s --health-retries=10
     steps:
     - uses: actions/checkout@v1 # pulls your repository, M2 src must be in a magento directory
     - name: 'this step will execute all the unit tests available'
       if: always()
       uses: MAD-I-T/magento-actions@v3.8
       env:
         COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
       with:
         php: '7.4'
         process: 'unit-test'
         elasticsearch: 1
     - name: 'this step starts static testing the code'
       if: always()
       uses: MAD-I-T/magento-actions@v3.8
       env:
         COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
       with:
         php: '7.4'
         process: 'static-test'
         elasticsearch: 1
     - name: 'this step will build an magento artifact'
       if: always()
       uses: MAD-I-T/magento-actions@v3.8
       env:
         COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
       with:
         php: '7.4'
         process: 'build'
         elasticsearch: 1
 ```
        

 Config Example when magento 2.3 & lower
 
```
name: m2-actions-test
on: [push]

jobs:
  magento2-build:
    runs-on: ubuntu-latest
    container: ubuntu
    name: 'm2 unit tests & build'
    services:
      mysql:
        image: docker://mysql:5.7
        env:
          MYSQL_ROOT_PASSWORD: magento
          MYSQL_DATABASE: magento
        ports:
          - 3106:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
    steps:
    - uses: actions/checkout@v1  # pulls your repository, M2 src must be in a magento directory
    - name: 'this step will execute all the unit tests available'
      if: always()
      uses: MAD-I-T/magento-actions@v2.0
      env:
        COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
      with:
        php: '7.2'
        process: 'unit-test'
     - name: 'this step starts static testing the code'
      if: always()
      uses: MAD-I-T/magento-actions@v3.8
      env:
        COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
      with:
        php: '7.2'
        process: 'static-test'
    - name: 'this step will build an magento artifact'
      if: always()
      uses: MAD-I-T/magento-actions@v2.0
      env:
        COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
      with:
        php: '7.1'
        process: 'build'
```
To use the latest experimental version of the module set the following : (`uses: MAD-I-T/magento-actions@master`)


##### options
- `php:` possible values (7.1, 7.2, 7.4)
- `process:` option [possible values](#other-processes) ('security-scan-files','static-test', 'integration-test', 'build'...)
- see more specific args in the inputs section in [actions.yml](https://github.com/MAD-I-T/magento-actions/blob/master/action.yml) 

Example with M2 project using elasticsuite & elasticsearch [here](https://github.com/seyuf/magento-actions)

![magento-actions-sample](https://user-images.githubusercontent.com/3765910/68416322-91bb9a00-0194-11ea-967d-9f139b901b9a.png)

# zero downtime deployment
To migrate from standard to zero-downtime deployment using this action.
One can follow this [tutorial](https://www.madit.fr/r/1PP).

**This step must come after a mandatory build step. **

For magento 2.4 

```
- name: 'this step will deploy your build to deployment server - zero downtime'
  uses: MAD-I-T/magento-actions@v3.8
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
    BUCKET_COMMIT: bucket-commit-${{github.sha}}.tar.gz
    MYSQL_ROOT_PASSWORD: magento
    MYSQL_DATABASE: magento
    HOST_DEPLOY_PATH: ${{secrets.STAGE_HOST_DEPLOY_PATH}}
    HOST_DEPLOY_PATH_BUCKET: ${{secrets.STAGE_HOST_DEPLOY_PATH}}/bucket
    SSH_PRIVATE_KEY: ${{secrets.STAGE_SSH_PRIVATE_KEY}}
    SSH_CONFIG: ${{secrets.STAGE_SSH_CONFIG}}
    WRITE_USE_SUDO: false
    with:
      php: '7.4'
      process: 'deploy-staging'

- name: 'unlock php deployer if the deployment fails'
  if: failure() || cancelled()
  uses: MAD-I-T/magento-actions@v3.8
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
    BUCKET_COMMIT: bucket-commit-${{github.sha}}.tar.gz
    MYSQL_ROOT_PASSWORD: magento
    MYSQL_DATABASE: magento
    HOST_DEPLOY_PATH: ${{secrets.STAGE_HOST_DEPLOY_PATH}}
    HOST_DEPLOY_PATH_BUCKET: ${{secrets.STAGE_HOST_DEPLOY_PATH}}/bucket
    SSH_PRIVATE_KEY: ${{secrets.STAGE_SSH_PRIVATE_KEY}}
    SSH_CONFIG: ${{secrets.STAGE_SSH_CONFIG}}
    WRITE_USE_SUDO: false
  with:
    php: '7.4'
    process: 'cleanup-staging'

```

For magento 2.3 and lower
```
- name: 'this step will deploy your build to deployment server - zero downtime'
  uses: MAD-I-T/magento-actions@v2.0
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
    BUCKET_COMMIT: bucket-commit-${{github.sha}}.tar.gz
    MYSQL_ROOT_PASSWORD: magento
    MYSQL_DATABASE: magento
    HOST_DEPLOY_PATH: ${{secrets.STAGE_HOST_DEPLOY_PATH}}
    HOST_DEPLOY_PATH_BUCKET: ${{secrets.STAGE_HOST_DEPLOY_PATH}}/bucket
    SSH_PRIVATE_KEY: ${{secrets.STAGE_SSH_PRIVATE_KEY}}
    SSH_CONFIG: ${{secrets.STAGE_SSH_CONFIG}}
    WRITE_USE_SUDO: false
  with:
    php: '7.1'
    process: 'deploy-staging'

- name: 'unlock php deployer if the deployment fails'
  if: failure() || cancelled()
  uses: MAD-I-T/magento-actions@v2.0
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
    BUCKET_COMMIT: bucket-commit-${{github.sha}}.tar.gz
    MYSQL_ROOT_PASSWORD: magento
    MYSQL_DATABASE: magento
    HOST_DEPLOY_PATH: ${{secrets.STAGE_HOST_DEPLOY_PATH}}
    HOST_DEPLOY_PATH_BUCKET: ${{secrets.STAGE_HOST_DEPLOY_PATH}}/bucket
    SSH_PRIVATE_KEY: ${{secrets.STAGE_SSH_PRIVATE_KEY}}
    SSH_CONFIG: ${{secrets.STAGE_SSH_CONFIG}}
    WRITE_USE_SUDO: false
  with:
    php: '7.1'
    process: 'cleanup-staging'

```
**The env section and values are mandatory** :
- `COMPOSER_AUTH`: `{"http-basic":{"repo.magento.com": {"username": "xxxxxxxxxxxxxx", "password": "xxxxxxxxxxxxxx"}}}
- `HOST_DEPLOY_PATH`: `/var/www/myeshop/`
- `HOST_DEPLOY_PATH_BUCKET` : `${{secrets.STAGE_HOST_DEPLOY_PATH}}/bucket` or `/var/www/myeshop/bucket/`
- `SSH_PRIVATE_KEY` : `your ssh key`
- `SSH_CONFIG` : [see more](https://github.com/MAD-I-T/magento-actions/blob/master/config/php-deployer/sshd_config_example)  adjust the values to match your server (Host must be staging or production)
     ```
       Host staging  //this must be staging or production
        User magento 
        IdentityFile ~/.ssh/id_rsa 
        HostName staging.server
        Port 12022
     ``` 
 - `WRITE_USE_SUDO`: true or false, the deployer will exec commands as sudo on remote server
 
 The first deploy will fail, unless/then you must place a valid env.php under dir HOST_DEPLOY_PATH/shared/magento/app/etc/ on the deployment endpoint.
 
 A cleanup task must be launched if the deployment fails ([see here](https://github.com/seyuf/m2-dev-github-actions/blob/b711485a721ca07926140c7cdcfb79e2183cefee/.github/workflows/main.yml#L74))
 
 **To achieve the deployment using gitlab-ci  ([follow this tutorial](https://github.com/MAD-I-T/magento-actions/tree/master/gitlab-deployer))**
  
# Other processes

- [install magento from github actions](#install-magento-action)
- [Code quality check](#code-quality-check)
- [Magento build](#build-an-artifact)
- [Magento security scanners](#magento-security-scanners)
- [Unit testing](#unit-testing)
- [Integration tests](#integration-testing)
- [Static testing](#static-test)
- [Customize the module](#customize-the-action)
- [Setting the secrets](#set-secrets)



## Install magento action
One can install magento using github actions. This action will download magento source code and copy it into the current github repository.
Make sure the repository does not contain the magento directory at the root.
You will also need to specify the version. Supported versions 2.3.X and 2.4.X
Or you can simply clone or fork this [repository](https://github.com/seyuf/magento-create-project) and use it as a template.

```
name: m2-install-actions
on: [push]
jobs:
  magento2-install:
    runs-on: ubuntu-latest
    name: 'magento install & push'      
    steps:
    - uses: actions/checkout@v2
    - name: 'install fresh magento and copy to repo'
      uses: MAD-I-T/magento-actions@v3.8
      env:
        COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
      with:
        process: 'create-project'
        magento_version: 2.3.0
```


<div align="center">
  <a href="https://www.youtube.com/watch?v=cqI79AKN7Gk"><img src="https://user-images.githubusercontent.com/3765910/154555377-2ab4d165-9bbb-42a4-b6cf-22586156477d.png" alt="install magento 2 using github actions"></a>
  <span>Install process in video</scan>
</div>


## Code quality check

To check some magento module or some code against Magento conding Standard, useful before marketplace submissions
<div align="center">
  <a href="https://www.youtube.com/watch?v=4kyj4Rerm9s"><img src="https://user-images.githubusercontent.com/3765910/132560118-50110b43-57a5-4fb2-9725-7994e79451d8.png" alt="check code against magento coding standard using github actions"></a>
</div>

For magento 2.4 and 2.3

```
- name: 'test some specific module code quality'
  uses: MAD-I-T/magento-actions@v3.8
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
  with:
    php: '7.2'
    process: 'phpcs-test'
    extension: 'Magento/CatalogSearch'
    standard: 'Magento2'
    severity: 10
```
- extension : the module to be tested (Vendor/Name) or Path using repository scaffolding (i.e from see example [here](https://github.com/MAD-I-T/Magento2-AtosSips-Sherlock-LCL/blob/master/.github/workflows/main.yml))
- standard : the standard for which the conformity must be checked 'Magento2, PSR2, PSR1, PSR12 etc...' see [magento-coding-standard](https://github.com/magento/magento-coding-standard)

## build an artifact

For magento 2.4.x

```
- name: 'This step will build an magento artifact'
  uses: MAD-I-T/magento-actions@v3.8
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
  with:
    php: '7.4'
    process: 'build'
    elasticsearch: 1
```

For magento 2.3 or lower

```
- name: 'This step will build an magento artifact'
  uses: MAD-I-T/magento-actions@v2.0
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
  with:
    php: '7.1'
    process: 'build'
```

- `php` : 7.1, 7.2 or 7.4

## Magento security scanners

Security scan actions should and must (in case of the modules scanner) be launched after a build job see example [here](https://github.com/seyuf/m2-dev-github-actions/blob/37b7a822ef09a961b7712d01707be08149770030/.github/workflows/main.yml#L37)

To scan the magento 2 files for common vulnerabilities using mwscan, the job can be set up as follows
 
For magento 2.4.x

```
- name: 'This step will scan the files for security breach'
  if: always()
  uses: MAD-I-T/magento-actions@v3.8
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
  with:
    php: '7.4'
    process: 'security-scan-files'
    elasticsearch: 1
    override_settings: 1
```

For magento 2.3 or lower

```
- name: 'This step will scan the files for security breach'
  if: always()
  uses: MAD-I-T/magento-actions@v2.0
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
  with:
    php: '7.1'
    process: 'security-scan-files'
```

To scan the magento2 installed third parties modules for known vulnerabilities using [sansecio/magevulndb](https://github.com/sansecio/magevulndb), the job can be set up as follows:

For magento 2.4.x

```
- name: 'This step will check all modules for security vulnerabilities'
      if: always()
      uses: MAD-I-T/magento-actions@v3.8
      env:
        COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
      with:
        php: '7.4'
        process: 'security-scan-modules'
        elasticsearch: 1
```

For magento 2.3 or lower

```
- name: 'This step will check all modules for security vulnerabilities'
      if: always()
      uses: MAD-I-T/magento-actions@v2.0
      env:
        COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
      with:
        php: '7.1'
        process: 'security-scan-modules'
```


Example of an output:

![security-risk-amasty](https://user-images.githubusercontent.com/3765910/117654360-f0047700-b195-11eb-8aff-ef05c2c3c231.png)



## unit testing

For magento 2.4.x
```
- name: 'This step will execute all the unit tests available'
  uses: MAD-I-T/magento-actions@v3.8
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
  with:
    php: '7.4'
    process: 'unit-test'
    elasticsearch: 1
```

For magento 2.3 or lower
```
- name: 'This step will execute all the unit tests available'
  uses: MAD-I-T/magento-actions@v2.0
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
  with:
    php: '7.1'
    process: 'unit-test'
```

## integration testing

Full sample, the integration test will need rabbitmq (this test will take a while to complete ^^)
```
magento2-integration-test:
runs-on: ubuntu-latest
container: ubuntu
name: 'm2 integration test'
services:
  mysql:
    image: docker://mysql:8
    env:
      MYSQL_ROOT_PASSWORD: magento
      MYSQL_DATABASE: magento
    options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=5 -e MYSQL_ROOT_PASSWORD=magento -e MYSQL_USER=magento -e MYSQL_PASSWORD=magento -e MYSQL_DATABASE=magento --entrypoint sh mysql:8 -c "exec docker-entrypoint.sh mysqld --default-authentication-plugin=mysql_native_password"
  elasticsearch:
    image: docker://elasticsearch:7.1.0
    ports:
      - 9200:9200
    options: -e="discovery.type=single-node" --health-cmd="curl http://localhost:9200/_cluster/health" --health-interval=10s --health-timeout=5s --health-retries=10
  rabbitmq:
    image: docker://rabbitmq:3.8-alpine
    env:
      RABBITMQ_DEFAULT_USER: "magento"
      RABBITMQ_DEFAULT_PASS: "magento"
      RABBITMQ_DEFAULT_VHOST: "/"
    ports:
      - 5672:5672

steps:
  - uses: actions/checkout@v1
    with:
      submodules: recursive
  - name: 'launch magento2 integration test'
    if: ${{false}}
    uses: MAD-I-T/magento-actions@v3.8
    env:
      COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
    with:
      php: '7.4'
      process: 'integration-test'
      elasticsearch: 1
```

## static-test

For magento 2.3 & 2.4
```
- name: 'This step starts static testing the code'
  uses: MAD-I-T/magento-actions@v3.8
  env:
    COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}
  with:
    php: '7.2'
    process: 'static-test'
```

## Customize the action

### To make all docker build on the runner (no usage of an external image)  
 For those cloning ...
 
 Replace in [action.yml](https://github.com/MAD-I-T/magento-actions/blob/2e31f0c3a49314070f808458a93fa325e4855ffa/action.yml#L25)
 
 ` image: 'docker://mad1t/magento-actions:latest'` 
   
   by
 
 ` image: 'Dockerfile'` 
 
 ### To override the files in default scripts and config directories without forking
  use the [override_settings](https://github.com/MAD-I-T/magento-actions/blob/2e31f0c3a49314070f808458a93fa325e4855ffa/action.yml#L11) set it to 1
  You'll also have to create scripts or config dirs in the root of your m2 project.
  [Example](https://github.com/seyuf/m2-dev-github-actions) of project scafolding to override the action's default configs
  ```bash
  ├── .github
  │   └── workflows # directory where the workflows are found, see below for an example of main.yml 
  ├── README.md 
  └── magento # directory where you Magento source files should go
  └── config # the filenames must be similar to thoses of the action ex: config/integration-test-config.php 
  └── scripts #  ex: scripts/build.sh to override the build behaviour 
  ```

## tipycal issues
   - Do not forget to set or replace the `env.php` file in the `shared` directory
   - Adding the ssh user to the `http-user` group ex. `www-data` , also check php pool user and group setting rights
   - Set `WRITE_USE_SUDO` env if you want to launch the deployment script in sudo mode (not necessary in most cases)
   - integration test when using magento 2.4
     - you will need to set mysql 8 docker with the options arg as such `        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=5 -e MYSQL_ROOT_PASSWORD=magento -e MYSQL_USER=magento -e MYSQL_PASSWORD=magento -e MYSQL_DATABASE=magento --entrypoint sh mysql:8 -c "exec docker-entrypoint.sh mysqld --default-authentication-plugin=mysql_native_password"
`
     - [see example here](https://github.com/seyuf/m2-dev-github-actions/blob/master/.github/workflows/main.yml#L104)
 
## Set secrets
  It is a good practice not to set credentials like composer auth in the code source (see https://12factor.net).
  So it is advised to use github secret instead of fill the value in the main.yml of your workflow. 
  Example for `COMPOSER_AUTH`:
  1. Go to `Settings>Secrets`
  2. Create variable `COMPOSER_AUTH`
  3. Add you composer auth as value e.g :
     `{"http-basic":{"repo.magento.com": {"username": "xxxxxxxxxxxxxx", "password": "xxxxxxxxxxxxxx"}}}`
  4. Use as follows `COMPOSER_AUTH: ${{secrets.COMPOSER_AUTH}}` in the action definition.
