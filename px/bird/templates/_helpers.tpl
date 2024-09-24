
{{- /*
All bird.domain.* expect a domain-context that should look like the following:
top: the root helm context including .Files, .Release, .Chart, .Values
service: service_1
service_number: 1
service_config: everything nested under .Values.services_1
domain_number: 1
domain_config: everything nested under .Values.service_1.domain_1
*/}}

{{- define "bird.afis" -}}
{{ $afis := list }}
{{- range $k, $v := .domain_config }}
  {{ if and (hasPrefix "network_v" $k) $v }}
    {{- $afis = append $afis (trimPrefix "network_" $k) }}
  {{- end }}
{{- end }}
{{ $afis | toJson }}
{{- end }}

{{- define "bird.domain.config_name" -}}
{{- printf "%s-pxrs-%d-s%d" .top.Values.global.region .domain_number .service_number }}
{{- end }}

{{- define "bird.domain.config_path"}}
{{- printf "%s%s.conf" .top.Values.bird_config_path  (include "bird.domain.config_name" .) -}}
{{- end }}

{{- define "bird.statefulset.name" }}
{{- printf "routeserver-%s-service-%d-domain-%d" .afi .service_number .domain_number }}
{{- end }}

{{- define "bird.domain.labels" }}
pxservice: '{{ .service_number }}'
px.cloud.sap/service: {{ .service_number | quote }}
pxdomain: '{{ .domain_number }}'
px.cloud.sap/domain: {{ .domain_number | quote }}
service: {{ .top.Release.Name | quote }}
{{- end }}

{{- define "bird.afi.labels" }}
px.cloud.sap/afi: {{ .afi | quote }}
{{- end }}

{{- define "bird.statefulset.labels" }}
app: {{ include "bird.statefulset.name" . | quote }}
{{- include "bird.domain.labels" . }}
{{- include "bird.afi.labels" . }}
{{- end }}


{{- define "bird.afi.network "}}

{{- end }}


{{- define "bird.alert.labels" }}
alert-tier: px
alert-service: px
{{- end }}

{{- define "bird.domain.affinity" }}
{{- if len .top.Values.apods  | eq 0 }}
{{- fail "You must supply at least one apod for scheduling" -}}
{{ end }}
nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.cloud.sap/apod
          operator: In
          values: 
          {{- range $site := keys .top.Values.apods | sortAlpha }}
          {{- range get $.top.Values.apods  $site | sortAlpha }}
          - {{ . }}
          {{- end }}
          {{- end }}
          {{- if .top.Values.prevent_hosts }}
        - key: kubernetes.cloud.sap/host
          operator: NotIn
          values:
          {{ .top.Values.prevent_hosts | toYaml | indent  16 }}
          {{- end }}
podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - topologyKey: "kubernetes.cloud.sap/host"
      labelSelector:
        matchExpressions:
        - key: px.cloud.sap/afi
          operator: In
          values:
          - {{ .afi | quote }}
        - key: pxservice
          operator: In
          values:
          - {{ .service_number | quote }}
          {{- if and (ge (len .top.Values.global.availability_zones ) 2) $.top.Values.az_redundancy }}
          {{- if lt (len (keys .top.Values.apods))  2 }}
          {{- fail "If the region consists of multiple AZs, PX must be scheduled in at least 2" -}}
          {{- end }}
    - topologyKey: topology.kubernetes.io/zone
      labelSelector:
        matchExpressions:
        - key: pxservice
          operator: In
          values:
          - {{ .service_number | quote }}
        - key: pxdomain
          operator: In
          values:
          - {{ .domain_number | quote }}
        - key: px.cloud.sap/afi
          operator: In
          values:
          - {{ .afi | quote }}
{{- end }}
{{- end }}

{{ define "bird.domain.tolerations"}}
{{- if .top.Values.tolerate_arista_fabric }}
- key: "fabric"
  operator: "Equal"
  value: "arista"
  effect: "NoSchedule"
{{- end }}
{{- end }}
