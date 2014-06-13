# This setup for mongodb assumes that the replica set can be determined from
# the id of the minion
# NOTE: Currently this will not work behind a NAT in AWS VPC. 
# see http://lodge.glasgownet.com/2012/07/11/apt-key-from-behind-a-firewall/comment-page-1/ for details

{% version = salt['pillar.get']('mongodb:version') %}

{% if version is not none %}

{% from "mongodb/map.jinja" import mongodb with context %}
{% set settings = salt['pillar.get']('mongodb:setings', {}) %}
{% set replica_set = salt['pillar.get']('mongodb:replica_set', {}) %}
{% set db_path = settings.get('db_path', '/data/db') %}
{% set log_path = settings.get('log_path', '/var/log/mongodb') %}

include:
  - .replica

mongodb_package:
{% if mongodb.use_ppa %}
  pkgrepo.managed:
    - humanname: MongoDB PPA
    - name: deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen
    - file: /etc/apt/sources.list.d/mongodb.list
    - keyid: 7F0CEB10
    - keyserver: keyserver.ubuntu.com
  pkg.installed:
    - name: mongodb-10gen
    {% if mongodb.version != None %}
    - version: {{ mongodb.version }}
    {% endif %}
{% else %}
  pkg.installed:
     - name: mongodb
{% endif %}

mongodb_db_path:
  file.directory:
    - name: {{ db_path }}
    - user: mongodb
    - group: mongodb
    - mode: 755
    - makedirs: True

mongodb_log_path:
  file.directory:
    - name: {{ log_path }}
    - user: mongodb
    - group: mongodb
    - mode: 755
    - makedirs: True

mongodb_service:
  service.running:
    - name: mongodb
    - enable: True
    - watch:
      - file: mongodb_configuration

mongodb_configuration:
  file.managed:
    - name: /etc/mongodb.conf
    - user: root
    - group: root
    - mode: 644
    - source: salt://mongodb/files/mongodb.conf.jinja
    - template: jinja
    - context:
        dbpath: {{ db_path }}
        logpath: {{ log_path }}
        port: {{ settings.get('port', 27017) }}
        replica_set: {{ replica_set }}

mongodb_logrotate:
  file.managed:
    - name: /etc/logrotate.d/mongodb
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://mongodb/files/logrotate.jinja

{% endif %}