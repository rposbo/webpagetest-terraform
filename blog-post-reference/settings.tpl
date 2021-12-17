ec2_key=${iam_key}
ec2_secret=${iam_secret}

waterfall_show_user_timing=1
iq=75
pngss=1

archive_s3_server=s3.amazonaws.com
archive_s3_key=${iam_key}
archive_s3_secret=${iam_secret}
archive_s3_bucket=${wpt_archive}
archive_days=1
cron_archive=1

EC2.tags="${agent_tags}"
${crux_api_key}
EC2.default=eu-west-1
