check "starrocks_secrets_source_exclusive" {
  assert {
    condition = (
      (var.secrets_manager.root_password_secret == "" && var.secrets_manager.ssl_secret == "") ||
      var.node_type != "fe" ||
      (
        try(var.fe_config.initial_leader.root_password, "") == "" &&
        try(var.fe_config.ssl.cert, "") == "" &&
        try(var.fe_config.ssl.key, "") == ""
      )
    )
    error_message = "When secrets_manager is set, fe_config.initial_leader.root_password and fe_config.ssl.cert/key must be empty: secrets come from Secrets Manager, not literals."
  }
}
