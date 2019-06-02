from invoke import task

# the public key for the piipeline, used to encode encryption keys
PIPELINE_KEY_PEM='~/.circleci/public/pipeline-public.pem'
PRIVATE_PEM='~/.circleci/private/private.pem'

@task
def encfile(ctx, decoded):
    """encrypt file using local encryption key"""
    ctx.run('openssl enc -aes-256-cbc -salt -in {0} -out {0}.enc -pass file:./key.bin'.format(decoded))
    ctx.run('sha256sum {0}.enc > {0}.enc.sha'.format(decoded))

@task
def enckey(ctx):
    """generate random 2048bit random key to use for encrypting secure files for this pipeline"""
    ctx.run('openssl rand -base64 32 > key.bin')
    ctx.run('openssl rsautl -encrypt -inkey {} -pubin -in key.bin -out key.bin.enc'.format(PIPELINE_KEY_PEM))
    ctx.run('sha256sum key.bin.enc > key.bin.enc.sha')

@task
def decfile(ctx, filename):
    """decrypt file encryption key with private.pem and decode file using local encryption key"""
    ctx.run('sha256sum --check --status key.bin.enc.sha')
    ctx.run('openssl rsautl -decrypt -inkey {} -in key.bin.enc -out key.bin'.format(PRIVATE_PEM))
    ctx.run('sha256sum --check --status {}.enc.sha'.format(filename))
    ctx.run('openssl enc -d -aes-256-cbc -in {0}.enc -out {0} -pass file:./key.bin'.format(filename))

@task
def validate(ctx):
    """validate circleci orb file"""
    ctx.run('circleci config pack src > orb.yml')
    ctx.run('circleci orb validate orb.yml')
    ctx.run('rm orb.yml')
