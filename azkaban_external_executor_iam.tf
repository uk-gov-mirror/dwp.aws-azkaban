resource "aws_iam_role" "azkaban_external_executor" {
  name               = "azkaban-external-executor"
  assume_role_policy = data.aws_iam_policy_document.azkaban_executor_assume_role.json
  tags               = merge(local.common_tags, { Name = "azkaban-external-executor" })
}

resource "aws_iam_role_policy_attachment" "azkaban_external_executor_read_config_attachment" {
  role       = aws_iam_role.azkaban_external_executor.name
  policy_arn = aws_iam_policy.azkaban_executor_read_config.arn
}

resource "aws_iam_role_policy_attachment" "azkaban_external_executor_emr_attachment" {
  role       = aws_iam_role.azkaban_external_executor.name
  policy_arn = aws_iam_policy.azkaban_executor_emr.arn
}

resource "aws_iam_role_policy_attachment" "azkaban_external_executor_logs_attachment" {
  role       = aws_iam_role.azkaban_external_executor.name
  policy_arn = aws_iam_policy.azkaban_executor_logs.arn
}
