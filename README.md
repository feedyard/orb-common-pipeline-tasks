# orb-common-pipeline-tasks [![CircleCI status](https://circleci.com/gh/feedyard/orb-common-pipeline-tasks.svg "CircleCI status")](https://circleci.com/gh/feedyard/orb-common-pipeline-tasks) [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/feedyard/common-pipeline-tasks)](https://circleci.com/orbs/registry/orb/feedyard/common-pipeline-tasks) [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/feedyard/orb-common-pipeline-tasks/master/LICENSE)

Set of common pipeline tasks

* decrypt local files using openssl aes-256-cbc key encryption
* setup aws credentials

See orb registry help and examples pages for use descriptions

### working with gnupg to create and use public and private keys

Generate new gpg RSA key from template (quiet)
```bash
$ cat > foo <<EOF
     %echo Generating a basic OpenPGP key
     Key-Type: RSA
     Key-Length: 4096
     Name-Real: pipeline-key
     Name-Comment: with no passphrase
     Name-Email: service.account@foo.bar
     Expire-Date: 0
     # Do a commit here, so that we can later print "done" :-)
     %commit
     %echo done
EOF
$ gpg --batch --generate-key foo
$ gpg --armor --export pipeline-key > public.asc
```

Export the private key
```bash
$ gpg --export-secret-keys --armor pipeline-key > private.asc
```

Import a public key and encrypt local file using public key
```bash
$ gpg --import public.asc
$ gpg --recipient pipeline-key --encrypt FILENAME
```

Import a private key and decode file encrypted with public key
```bash
$ gpg --import private.asc
$ gpg --decrypt FILENAME.gpg > FILENAME
```

The common-pipeline-tasks orb expects the private.asc to be available in base64 encoded format in an Environment variable.
Use circleci api to upload the private key to a Context or do the following to copy the private key and paste into the
teams circleci 'context' environment variable.
```bash
$ cat private.asc | base64 | pbcopy
```

### working with openssl to create and use public and private keys

Generate new RSA key and encrypt with a pass phrase based on AES CBC 256
```bash
$ openssl genrsa -aes256 -out private.pem 2048
```

Remove the passphrase from the key
```bash
$ openssl rsa -in private.pem -out private.pem
```

Extract the public key
```bash
$ openssl rsa -in private.pem -outform PEM -pubout -out public.pem
```

Generate random key for the repo to use for encrypting files
```bash
$ openssl rand -base64 32 > key.bin
```

Encrypt file using local encryption key
```bash
$ openssl enc -aes-256-cbc -md sha512 -salt -in FILENAME -out FILENAME.enc -pass file:./key.bin
```

Encrypt the local random encryption key using the public key
```bash
$ openssl rsautl -encrypt -inkey public.key -pubin -in key.bin -out key.bin.enc
```

Decrypt local key using private.pem
```bash
$ openssl rsautl -decrypt -inkey private.pem -in key.bin.enc -out key.bin
```

Decrypt a file using the local encryption key
```bash
$ openssl enc -d -aes-256-cbc -md sha512 -in FILENAME.enc -out FILENAME -pass file:./key.bin
```
