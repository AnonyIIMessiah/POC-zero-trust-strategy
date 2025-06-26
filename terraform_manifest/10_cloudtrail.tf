variable "trail_name" {
  default = "POC-trail"
}

variable "s3_bucket_name" {
  default = "cloudtrail-logs-poc-bucket"
}

resource "aws_kms_key" "cloudtrail_kms" {
  description             = "KMS key for CloudTrail logs encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid       = "Allow administration of the key"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = [
          "kms:*"
        ]
        Resource  = "*"
      },
      {
        Sid       = "Allow CloudTrail to use the key"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/POC-trail"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_server_side_encryption_configuration" "kms_encryption" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail_kms.arn
    }
  }
}


resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = var.s3_bucket_name

  force_destroy = true

  tags = {
    Name = "CloudTrail Logs"
  }
}

# Allow CloudTrail to write to the bucket
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.id}"
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_bucket.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}




resource "aws_cloudwatch_log_group" "trail_log_group" {
  name = "/aws/cloudtrail/logs"
  retention_in_days = 60
}

resource "aws_iam_role" "cloudtrail_role" {
  name = "CloudTrail_CloudWatch_Logs_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_policy" {
  name = "CloudTrailLogsPolicy"
  role = aws_iam_role.cloudtrail_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ],
        Resource = "${aws_cloudwatch_log_group.trail_log_group.arn}:*"
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket
  kms_key_id                    = aws_kms_key.cloudtrail_kms.arn

  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn   = "${aws_cloudwatch_log_group.trail_log_group.arn}:*"
  cloud_watch_logs_role_arn    = aws_iam_role.cloudtrail_role.arn
    # to get logs of lambda functions in this log group, else getting in the default log group inside the lambda function
    # event_selector {
    # read_write_type           = "All"
    # include_management_events = true

    # data_resource {
    #     type   = "AWS::Lambda::Function"
    #     values = [aws_lambda_function.product-service.arn, aws_lambda_function.user-service.arn]
    # }
    # }
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_bucket_policy,
    aws_kms_key.cloudtrail_kms
  ]
}
