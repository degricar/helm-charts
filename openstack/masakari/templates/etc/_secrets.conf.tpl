[oslo_messaging_amqp]
{{- include "ini_sections.default_transport_url" . }}

[database]
connection = {{ tuple . .Values.mariadb.name .Values.mariadb.users.masakari.name .Values.mariadb.users.masakari.password | include "db_url_mysql" }}

[keystone_authtoken]
username = {{ .Values.global.masakari_service_user | default "masakari" }}
password = {{ required ".Values.global.masakari_service_password is missing" .Values.global.masakari_service_password }}

[taskflow]
connection = {{ tuple . .Values.mariadb.name .Values.mariadb.users.masakari.name .Values.mariadb.users.masakari.password | include "db_url_mysql" }}
