# orb-common-pipeline-tasks [![CircleCI status](https://circleci.com/gh/feedyard/orb-common-pipeline-tasks.svg "CircleCI status")](https://circleci.com/gh/feedyard/orb-common-pipeline-tasks) [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/feedyard/common-pipeline-tasks)](https://circleci.com/orbs/registry/orb/feedyard/common-pipeline-tasks) [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/feedyard/orb-common-pipeline-tasks/master/LICENSE)

Set of common pipeline tasks

* decrypt local files using openssl aes-256-cbc key encryption
* setup aws credentials

See orb registry help and examples pages for use descriptions

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
$ openssl enc -aes-256-cbc -salt -in FILENAME -out FILENAME.enc -pass file:./key.bin
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
$ openssl enc -d -aes-256-cbc -in FILENAME.enc -out FILENAME -pass file:./key.bin
```
