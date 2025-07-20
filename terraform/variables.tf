variable "aws_region" {
  description = "AWS region"
  default = "ap-northeast-2"
}

variable "project_name" {
  description = "Name of the project"
  default = "thumbnail-project"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for images"
  default = "post-images"
}

variable "db_name" {
  description = "The name of the database to create."
  default = "post_db"
}

variable "db_user" {
  description = "The username for the database."
  default = "admin"
}

variable "db_password" {
  description = "The password for the database user."
  sensitive = true
}

