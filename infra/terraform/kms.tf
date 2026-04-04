resource "aws_kms_key" "votechain_key" {
  description             = "VoteChain encryption key for vote data and secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-kms-key"
  }
}

resource "aws_kms_alias" "votechain_key_alias" {
  name          = "alias/${var.project_name}-key"
  target_key_id = aws_kms_key.votechain_key.key_id
}
