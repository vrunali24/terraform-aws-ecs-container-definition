variable "service_name" {
  default = "Name of the service."
}

variable "service_image" {
  description = "URL to the service image. Currently only Docker Hub an ECR are supported."
}

variable "cpu" {
  description = "Number of CPU units to assign to this task."
}

variable "memory" {
  description = "Memory in MegaBytes to assign to this task."
}

variable "log_configuration" {
  type = object({
    logDriver: string
    options: object({
      Name:  string,
      licenseKey: string,
      endpoint = string
    })
  })
}

variable "port_mappings" {
  type = list(object({
    hostPort = string
    containerPort = string
  }))
  default = [
    {
      hostPort      = "__NOT_DEFINED__"
      containerPort = "__NOT_DEFINED__"
    },
  ]
}

variable "secrets" {
  type = list(object({
    name = string
    valueFrom = string
  }))
  default = []
  description = "This is used to pass secrets to the containers. Please make sure you have attached the appropriate task execution role with the task."
}

variable "links" {
  type    = list(string)
  default = []
}

variable "essential" {
  default = true
}

variable "entrypoint" {
  default = ""
}

variable "service_command" {
  default     = ""
  description = "The command that needs to run at startup of the task."
}

variable "environment_vars" {
  type = map(string)
}



