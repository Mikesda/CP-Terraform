variable "access_key" {
  description = "Access key to AWS console"
  type        = string
}

variable "secret_key" {
  description = "Secret key to AWS console"
  type        = string
}

variable "session_token" {
  description = "Session token to AWS console"
  type        = string
}

variable "region" {
  description = "AWS region"
  default     = "us-west-2"
}
