variable "name_app" {
  type = string
  validation {
    condition = length(var.name_app) > 0
    error_message = "The name_app must be at least one character long."
  }
}
