# If VAR is unset or empty → set it to a DEFAULT
# ISP Tenant Info
if (-not $env:TENANT_ID)        { $env:TENANT_ID        = "SET_TENANT_ID" }
if (-not $env:TENANT_SUBDOMAIN) { $env:TENANT_SUBDOMAIN = "SET_TENANT_SUBDOMAIN" }

# ISP Service Account User
if (-not $env:CLIENT_ID)        { $env:CLIENT_ID        = "SET_CLIENT_ID" }
if (-not $env:CLIENT_SECRET)   { $env:CLIENT_SECRET   = "SET_CLIENT_SECRET" }

# ISP Service Account Installer User
if (-not $env:INSTALLER_USR)    { $env:INSTALLER_USR    = "SET_INSTALLER_USR" }
if (-not $env:INSTALLER_PWD)    { $env:INSTALLER_PWD    = "SET_INSTALLER_PWD" }
