# resource "aws_iam_role" "vpc_flow_log_role" {
#   name = "vpc-flow-logs-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "vpc-flow-logs.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "vpc_flow_logs_cloudwatch" {
#   role       = aws_iam_role.vpc_flow_log_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
# }

# resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
#   name              = "/vpc/flowlogs"
#   retention_in_days = 7
# }

# resource "aws_flow_log" "vpc_flow_logs" {
#   log_destination_type = "cloud-watch-logs"
#   log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
#   iam_role_arn         = aws_iam_role.vpc_flow_log_role.arn
#   vpc_id               = aws_vpc.POC-01.id
#   traffic_type         = "ALL" # ACCEPT | REJECT | ALL
# }


