# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :logger,
  handle_otp_reports: false,
  handle_sasl_reports: false

config :logger, :default_formatter, format: "$time[$level] $metadata $message\n"

config :logger, :default_handler,
  config: %{
    sync_mode_qlen: 1_000,
    drop_mode_qlen: 4_000,
    flush_qlen: 5_000,
    burst_limit_max_count: 2_000
  }

config :inventory, :logger, [
  {
    :handler,
    :file_log,
    :logger_std_h,
    %{
      config: %{
        drop_mode_qlen: 10_000,
        sync_mode_qlen: 5_000,
        flush_qlen: 11_000,
        file: ~c"_build/system.log",
        filesync_repeat_interval: 5000,
        file_check: 5000,
        max_no_bytes: 50_000_000,
        max_no_files: 5,
        compress_on_rotate: true
      }
    }
  }
]

config :gettext, :default_locale, "en"
