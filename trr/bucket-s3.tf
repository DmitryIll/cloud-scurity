

// Создаем сервисный аккаунт для backet
resource "yandex_iam_service_account" "sa_bucket" {
  folder_id = var.folder_id
  name      = "sa-bucket"
}

// Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa_bucket.id}"
  depends_on = [yandex_iam_service_account.sa_bucket]
}

// Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.sa_bucket.id
  description        = "static access key for object storage"
}

# Scurity

resource "yandex_resourcemanager_folder_iam_member" "sa-encrypter-decrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.sa_bucket.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "encrypter-decrypter-ig" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  # member    = "serviceAccount:ajep5fsnk0dh3ji83ang"
  member    = "serviceAccount:${yandex_iam_service_account.sa-lamp-group.id}"
}

resource "yandex_kms_symmetric_key" "key-sym" {
  name              = "symmetric-key"
  description       = "key for bucket encryption"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // equal to 1 year
}


// Создание бакета с использованием ключа
resource "yandex_storage_bucket" "s3backet2" {
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  bucket = var.bucket_name
  acl    = "public-read"
  
  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-sym.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "cat-picture" {
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  bucket = var.bucket_name
  key    = "cat"
  source = "./cat.jpg"
  acl = "public-read"
  depends_on = [yandex_storage_bucket.s3backet2]
}




