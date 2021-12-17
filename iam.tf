# IAM config
resource "aws_iam_user" "wpt-user" {
  name = "wpt-user"
}

resource "aws_iam_user_policy_attachment" "ec2-policy-attach" {
  user = "${aws_iam_user.wpt-user.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_user_policy_attachment" "s3-policy-attach" {
  user = "${aws_iam_user.wpt-user.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_access_key" "wpt-user" {
  user = "${aws_iam_user.wpt-user.name}"
}
