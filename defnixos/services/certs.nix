{ openssl
, wait-for-file
, writeScript
, bash
, service-types
}:

let
  # Should this be a param?
  x509-directory = "/etc/x509";

  subject =
    "/C=SG/ST=Singapore/O=Zalora/OU=DevOps/CN=$name-$id/emailAddress=it-services@zalora.com";

  script = writeScript "generate-x509" ''
    #!${bash}/bin/bash -e
    name=$1
    user=$2
    if [ ! -f ${x509-directory}/$name.crt ]; then
      mkdir -p ${x509-directory}

      oldmask=`umask`
      umask 0077
      ${openssl}/bin/openssl genrsa -out ${x509-directory}/$name.pem 2048
      chown $user ${x509-directory}/$name.pem
      umask $oldmask

      id=`cat /etc/machine-id`
      ${openssl}/bin/openssl req -out ${x509-directory}/$name.csr -new -subj ${subject} \
        -key ${x509-directory}/$name.pem

      ${wait-for-file} ${x509-directory}/$name.crt
    fi
  '';
in

{ service-name
, user ? service-name
}:

{
  description = "Generate x509 csr/key pair for ${service-name}";

  start = [ script service-name user ];

  type = service-types.oneshot;
}
