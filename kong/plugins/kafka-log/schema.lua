local types = require "kong.plugins.kafka-log.types"
local utils = require "kong.tools.utils"
local typedefs = require "kong.db.schema.typedefs"

--- Validates value of `bootstrap_servers` field.
local function check_bootstrap_servers(values)
    if values and 0 < #values then
        for _, value in ipairs(values) do
            local server = types.bootstrap_server(value)
            if not server then
                return false, "invalid bootstrap server value: " .. value
            end
        end
        return true
    end
    return false, "bootstrap_servers is required"
end

return {
    name = "kafka-log",
    fields = {
        { consumer = typedefs.no_consumer },
        { protocols = typedefs.protocols_http },
        {
            config = {
                type = "record",
                fields = {
                    { bootstrap_servers = { type = "array", elements = { type = "string" }, required = true } },
                    { topic = { type = "string", required = true } },
                    { timeout = { type = "number", default = 10000 } },
                    { keepalive = { type = "number", default = 60000 } },
                    { producer_request_acks = { type = "number", default = 1, one_of = { -1, 0, 1 } } },
                    { producer_request_timeout = { type = "number", default = 2000 } },
                    { producer_request_limits_messages_per_request = { type = "number", default = 200 } },
                    { producer_request_limits_bytes_per_request = { type = "number", default = 1048576 } },
                    { producer_request_retries_max_attempts = { type = "number", default = 10 } },
                    { producer_request_retries_backoff_timeout = { type = "number", default = 100 } },
                    { producer_async = { type = "boolean", default = true } },
                    { producer_async_flush_timeout = { type = "number", default = 1000 } },
                    { producer_async_buffering_limits_messages_in_memory = { type = "number", default = 50000 } },
                    { uuid = { type = "string", uuid = true } }
                },
            },
        },
    },
    entity_checks = {
        { custom_entity_check = {
            field_sources = { "config" },
            fn = function(entity)
                local config = entity.config
                --在更新的时候，自动生成uuid，作为producers_cache的key
                config.uuid = utils.uuid()
                --执行自定义校验逻辑
                local ok, err = check_bootstrap_servers(config.bootstrap_servers)
                if not ok then
                    return nil, err
                end

                return true
            end
        } },
    },
}
