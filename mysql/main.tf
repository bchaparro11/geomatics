provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_sql_database_instance" "mysql-master" {
  name             = "mysql-master"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier              = "db-n1-standard-2"
    availability_type = "ZONAL"
    disk_size         = 20
    backup_configuration {
      enabled = true
      binary_log_enabled             = true
    }
    ip_configuration {
      ipv4_enabled = true
    }

    database_flags {
      name  = "log_bin_trust_function_creators"
      value = "on"
    }

    database_flags {
      name  = "binlog_expire_logs_seconds"
      value = "86400"
    }

  }
}

resource "google_sql_database_instance" "mysql_replica_1" {
  name             = "mysql-replica-1"
  region           = "asia-east2"
  database_version = "MYSQL_8_0"
  master_instance_name = google_sql_database_instance.mysql-master.name

  settings {
    tier = "db-n1-standard-2"
    disk_size = 20
    
  }
}

resource "google_sql_database_instance" "mysql_replica_2" {
  name             = "mysql-replica-2"
  region           = "europe-west3"
  database_version = "MYSQL_8_0"
  master_instance_name = google_sql_database_instance.mysql-master.name

  settings {
    tier = "db-n1-standard-2"
    disk_size = 20
  }
}

resource "google_sql_user" "root" {
  name     = ""
  instance = google_sql_database_instance.mysql-master.name
  password = ""
}
