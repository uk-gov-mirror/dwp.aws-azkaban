resource "aws_iam_role" "azkaban_external_webserver" {
  name               = "azkaban-external-webserver"
  assume_role_policy = data.aws_iam_policy_document.azkaban_webserver_assume_role.json
  tags               = merge(local.common_tags, { Name = "azkaban-external-webserver" })
}

resource "aws_iam_role_policy_attachment" "azkaban_external_webserver_read_config_attachment" {
  role       = aws_iam_role.azkaban_external_webserver.name
  policy_arn = aws_iam_policy.azkaban_webserver_read_config.arn
}

resource "aws_iam_role_policy_attachment" "azkaban_external_webserver_read_secret_attachment" {
  role       = aws_iam_role.azkaban_external_webserver.name
  policy_arn = aws_iam_policy.azkaban_webserver_read_secret.arn
}

resource "aws_iam_policy" "azkaban_external_webserver_read_config" {
  name        = "AzkabanExternalWebserverReadConfigPolicy"
  description = "Allow Azkaban external webserver to read from config bucket"
  policy      = data.aws_iam_policy_document.azkaban_webserver_read_config.json
}

resource "aws_iam_policy" "azkaban_external_webserver_read_secret" {
  name        = "AzkabanExternalWebserverReadSecretPolicy"
  description = "Allow Azkaban external webserver to read from secrets manager"
  policy      = data.aws_iam_policy_document.azkaban_webserver_read_secret.json
}
