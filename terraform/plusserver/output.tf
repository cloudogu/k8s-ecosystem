output "shoot_name" {
  //value = var.shoot_name != "" ? var.shoot_name : "${var.shoot_name_prefix}${random_string.id.result}"
  value = "${var.shoot_name_prefix}${random_string.id.result}"
}