definition = {
  "/v1/as/{aId}/bs/{bId}" = {
    "GET" = {
      lambda = {
        function_name = "20a663b8-2c6b-4d57-9bce-be9387fb1a3e"
      }
    }
  }
}

stages                       = ["dev", "prd"]
endpoint_type                = "PRIVATE"
vpc_id                       = "63118f7d-b4ea-4d14-8961-9a93520481c8"
vpc_endpoint_ids             = ["63118f7d-b4ea-4d14-8961-9a93520481c7"]
disable_execute_api_endpoint = false
