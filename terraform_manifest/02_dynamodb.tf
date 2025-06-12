resource "aws_dynamodb_table" "Users" {
  name         = "Users"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }  
}

resource "aws_dynamodb_table" "Products" {
  name         = "Products"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }  
}