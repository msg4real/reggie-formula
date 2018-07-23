base:
  'vagrant':
    - vagrant
    - glusterfs.server
    - glusterfs.client
    - haproxy
    - nginx
    - postgres
    - rabbitmq
    - redis.server
    - reggie.db
    - reggie.scheduler
    - reggie.worker
    - reggie.web
    - reggie.devenv
    - ignore_missing: True
