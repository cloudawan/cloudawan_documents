# Authorization RBAC

# Auto scaling

# Monitoring

# Notification

# Audit log

An audit log is a security-relevant chronological record for the command issued by the user. Each component of the platform has every single access entry, that is rest api uri, mapping to the specifc audit log type. The whole command including the input data and parameters is recorded in the audit log except some privacy-related places where the credentials are ignored in the audit logs.

The audit logs are indexed and maintained by ElasticSearch. Except the simple query from GUI, such as by user, the complexity query could be executed with ElasticSearch DSL via Rest API. For example, it is possible to find out the most frequent user deploying the application A and getting failures within in the certain period.

# Network file system