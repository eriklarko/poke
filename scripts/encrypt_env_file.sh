openssl enc -aes-256-cbc -pbkdf2 -iter 20000 -salt -in .env -out .env.encrypted
