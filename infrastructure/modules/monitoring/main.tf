# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app" {
  name = "/ecs/${var.app_name}"
  tags = {
    Name = "${var.app_name}-log-group"
  }
}

# CloudWatch Metric Alarm for ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.app_name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert on ALB 5xx errors"
  alarm_actions       = [aws_sns_topic.scaling_notifications.arn]
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# CloudWatch Metric Alarm for High CPU (Scale Out)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.high_cpu_threshold
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn, aws_sns_topic.scaling_notifications.arn]
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# CloudWatch Metric Alarm for Low CPU (Scale In)
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.app_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.low_cpu_threshold
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn, aws_sns_topic.scaling_notifications.arn]
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# Auto Scaling Policy for Scale Out
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.app_name}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = var.asg_name
}

# Auto Scaling Policy for Scale In
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.app_name}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = var.asg_name
}

# SNS Topic for Scaling Notifications
resource "aws_sns_topic" "scaling_notifications" {
  name = "${var.app_name}-scaling-notifications"
}

# Auto Scaling Notification
resource "aws_autoscaling_notification" "scaling_events" {
  group_names = [var.asg_name]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE"
  ]
  topic_arn = aws_sns_topic.scaling_notifications.arn
}