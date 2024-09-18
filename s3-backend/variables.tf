variable "region" {
  type = string
  default = "ap-southeast-1"
}

variable "profile" {
  type = string
  default = "aws-projects-admin"
}

variable "project" {
  type        = string
  default     = "s3-backend"
}

variable "principal_arns" {
  description = "A list of principal arns allowed to assume the IAM role"
  default     = ["arn:aws:iam::920372990740:user/admin"]
  type        = list(string)
}