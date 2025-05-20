# values.yaml.tpl
clusterName: ${cluster_id}
serviceAccount:
  create: ${service_account_create}
  name: ${service_account_name}
  annotations:
    eks.amazonaws.com/role-arn: ${role_arn}
region: ${region}
vpcId: ${vpc_id}
image:
  repository: ${image_repo}
  tag: ${image_tag}