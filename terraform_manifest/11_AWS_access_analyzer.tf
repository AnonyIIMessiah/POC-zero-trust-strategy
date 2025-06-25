# This Terraform configuration creates an AWS Access Analyzer
# resource "aws_accessanalyzer_analyzer" "example" {
#   analyzer_name = "example"
#   type          = "ORGANIZATION_UNUSED_ACCESS"

#   configuration {
#     unused_access {
#       unused_access_age = 180
#       analysis_rule {
#         exclusion {
#           account_ids = []
#         }
#         # exclusion {
#         #   resource_tags = [
#         #     { key1 = "value1" },
#         #     { key2 = "value2" },
#         #   ]
#         # }
#       }
#     }
#   }
# }