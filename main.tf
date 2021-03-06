data "template_file" "_log_configuration" {
  #  depends_on = ["data.template_file._log_driver_options"]
  template = <<JSON
$${ jsonencode("logConfiguration") } : $${ log_configuration}
JSON


  vars = {
    log_configuration = jsonencode(var.log_configuration)
  }
}

data "template_file" "_port_mappings" {
  #  depends_on = ["data.template_file._port_mapping"]
  template = <<JSON
$${val}
JSON


  #host_port == "__NOT_DEFINED__" && container_port == "__NOT_DEFINED__" && protocol == "__NOT_DEFINED__" ? $${ jsonencode([])} : $${val}
  vars = {
    val = join(",\n", data.template_file._port_mapping.*.rendered)
    host_port = lookup(var.port_mappings[0], "hostPort", "")
    container_port = var.port_mappings[0]["containerPort"]
    protocol = lookup(var.port_mappings[0], "protocol", "")
  }
}

data "template_file" "_port_mapping" {
  count = var.port_mappings[0]["containerPort"] == "__NOT_DEFINED__" ? 0 : length(var.port_mappings)
  template = <<JSON
{
$${join(",\n",
  compact(
    list(
    host_port == "" || host_port == "__NOT_DEFINED_" ? "" : "$${ jsonencode("hostPort") }: $${host_port}",
    container_port == "" || container_port == "__NOT_DEFINED_" ? "" : "$${jsonencode("containerPort")}: $${container_port}",
    protocol == "" || protocol == "__NOT_DEFINED_" ? "" : "$${ jsonencode("protocol") }: $${jsonencode(protocol)}"
    )
  )
)}
}
JSON


  vars = {
    host_port = lookup(var.port_mappings[count.index], "hostPort", "")
    container_port = var.port_mappings[count.index]["containerPort"]
    protocol = lookup(var.port_mappings[count.index], "protocol", "")
  }
}

data "template_file" "_environment_vars" {
  count = lookup(var.environment_vars, "__NOT_DEFINED__", "__ITS_DEFINED__") == "__NOT_DEFINED__" ? 0 : 1
  depends_on = [
    data.template_file._environment_var]
  template = <<JSON
$${ jsonencode("environment") } : [
$${val}
]
JSON


  vars = {
    val = join(",\n", data.template_file._environment_var.*.rendered)
  }
}

data "template_file" "_environment_var" {
  count = length(keys(var.environment_vars)) > 0 ? length(keys(var.environment_vars)) : 0
  template = <<JSON
{
$${join(",\n",
  compact(
    list(
    var_name == "__NOT_DEFINED__" ? "" : "$${ jsonencode("name") }: $${ jsonencode(var_name)}",
    var_value == "__NOT_DEFINED__" ? "" : "$${ jsonencode("value") }: $${ jsonencode(var_value)}"
    )
  )
)}
}
JSON


  vars = {
    var_name = sort(keys(var.environment_vars))[count.index]
    var_value = lookup(
    var.environment_vars,
    sort(keys(var.environment_vars))[count.index],
    "",
    )
  }
}

data "template_file" "_ulimit" {
  template = jsonencode([
    {
      name = "nofile",
      softLimit = 30000
      hardLimit = 50000
    }
  ])
}

data "template_file" "_logrouter" {
  template = jsonencode({
    essential = true,
    // Image below is New Relic's fluentbit output plugin available on ECR
    image = "533243300146.dkr.ecr.eu-west-1.amazonaws.com/newrelic/logging-firelens-fluentbit",
    name = "log_router",
    memoryReservation = 50,
    logConfiguration = {
      logDriver = "json-file"
    }
    firelensConfiguration = {
      type = "fluentbit",
      options = {
        enable-ecs-log-metadata = "true"
      }
    }
  })
}

data "template_file" "_secrets" {
  template = <<JSON
$${ jsonencode("secrets") } : $${ secrets}
JSON


  vars = {
    secrets = jsonencode(var.secrets)
  }
}


data "template_file" "_final" {
  depends_on = [
    data.template_file._environment_vars,
    data.template_file._port_mappings,
    data.template_file._log_configuration,
    data.template_file._secrets
  ]
  template = <<JSON
[{
  $${val}
}, $${logRouter}]
JSON


  vars = {
    val = join(
    ",\n    ",
    compact(
    [
      "${jsonencode("cpu")}: ${var.cpu}",
      "${jsonencode("memory")}: ${var.memory}",
      "${jsonencode("entryPoint")}: ${jsonencode(compact(split(" ", var.entrypoint)))}",
      "${jsonencode("command")}: ${jsonencode(compact(split(" ", var.service_command)))}",
      "${jsonencode("links")}: ${jsonencode(var.links)}",
      "${jsonencode("portMappings")}: [${data.template_file._port_mappings.rendered}]",
      join("", data.template_file._environment_vars.*.rendered),
      join("", data.template_file._log_configuration.*.rendered),
      "${jsonencode("name")}: ${jsonencode(var.service_name)}",
      "${jsonencode("image")}: ${jsonencode(var.service_image)}",
      "${jsonencode("essential")}: ${var.essential ? true : false}",
      "${jsonencode("ulimits")}: ${data.template_file._ulimit.rendered}",
      join("", data.template_file._secrets.*.rendered),
    ],
    ),
    )
    logRouter = data.template_file._logrouter.rendered
  }
}




