# resource "aws_guardduty_detector" "this" {
#   enable = true
# }
# resource "aws_sns_topic" "guardduty_topic" {
#   name = "guardduty-alert-topic"
# }
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.guardduty_topic.arn
#   protocol  = "email"
#   endpoint  = "vaman1650.a@gmail.com" # Replace with your email
# }
# resource "aws_cloudwatch_event_rule" "guardduty_findings" {
#   name        = "guardduty-findings-to-sns"
#   description = "Forward GuardDuty findings to SNS"
#   event_pattern = jsonencode({
#     source      = ["aws.guardduty"],
#     detail-type = ["GuardDuty Finding"]
#   })
# }
# resource "aws_cloudwatch_event_target" "sns_target" {
#   rule      = aws_cloudwatch_event_rule.guardduty_findings.name
#   target_id = "send-to-sns"
#   arn       = aws_sns_topic.guardduty_topic.arn
# }
# resource "aws_sns_topic_policy" "allow_eventbridge" {
#   arn = aws_sns_topic.guardduty_topic.arn

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid    = "Allow_EventBridge_Publish",
#         Effect = "Allow",
#         Principal = {
#           Service = "events.amazonaws.com"
#         },
#         Action   = "sns:Publish",
#         Resource = aws_sns_topic.guardduty_topic.arn
#       }
#     ]
#   })
# }
