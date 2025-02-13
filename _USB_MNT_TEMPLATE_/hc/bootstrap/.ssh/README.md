Place any existing ssh keypair files `(ie, id_rsa[$|.pub])` in this directory that may have been previously generated and would like to maintain on the new instance. This is helpful to avoid auth issues (using authorized keys) from remote hosts on the network.

If the RSA keypair is not provided in this directory, `00-init.sh` will generate a new one.

Files copied [ _ref: https://github.com/datamonk/milhouse-init/blob/main/00-init.sh#L115 ]
 - 'id_rsa'
 - 'id_rsa.pub'
