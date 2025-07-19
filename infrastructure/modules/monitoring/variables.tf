variable "app_name" {
  description = "Application name prefix"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "high_cpu_threshold" {
  description = "CPU utilization threshold for scaling out"
  type        = number
  default     = 70
}

variable "low_cpu_threshold" {
  description = "CPU utilization threshold for scaling in"
  type        = number
  default     = 20
}