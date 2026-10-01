project_name = "electro"
environment  = "dev"
region       = "us-east-1"

db_name     = "electrodb"
db_username = "seif_adel"

# Do not commit real secrets.
# Set db_password via TF_VAR_db_password env var or CI secret.
db_password = "seif-adel-123"

# Optional: set email to receive CloudWatch alarm notifications.
alert_email = "seif.arabesque@gmail.com"
