require 'openssl'
require 'rsa'

KeyPair = Struct.new(:public_key, :private_key)

module Crypto
  def self.generate_keypair
    keypair = KeyPair.new

    key = RSA::KeyPair.generate(2048)

    public_key = key.public_key
    m = public_key.modulus
    e = public_key.exponent

    modulus = ""
    until m == 0 do
      modulus << [m % 256].pack("C")
      m >>= 8
    end
    modulus.reverse!

    exponent = ""
    until e == 0 do
      exponent << [e % 256].pack("C")
      e >>= 8
    end
    exponent.reverse!

    keypair.public_key = "RSA.#{Base64::urlsafe_encode64(modulus)}.#{Base64::urlsafe_encode64(exponent)}"

    tmp_private_key = key.private_key
    m = tmp_private_key.modulus
    e = tmp_private_key.exponent

    modulus = ""
    until m == 0 do
      modulus << [m % 256].pack("C")
      m >>= 8
    end
    modulus.reverse!

    exponent = ""
    until e == 0 do
      exponent << [e % 256].pack("C")
      e >>= 8
    end
    exponent.reverse!

    keypair.private_key = "RSA.#{Base64::urlsafe_encode64(modulus)}.#{Base64::urlsafe_encode64(exponent)}"

    keypair
  end

  # We don't yet do anything with the public key, but I added it so that when we
  # need to, it'll be there.
  def self.make_rsa_key(public_key, private_key)
    # Retrieve the exponent and modulus from the key string
    private_key.match /^RSA\.(.*?)\.(.*)$/
    modulus = Base64::urlsafe_decode64($1)
    exponent = Base64::urlsafe_decode64($2)

    modulus = modulus.bytes.inject(0) {|num, byte| (num << 8) | byte }
    exponent = exponent.bytes.inject(0) { |num, byte| (num << 8) | byte }

    # Create the public key instance
    key = RSA::Key.new(modulus, exponent)
    RSA::KeyPair.new(key, nil)
  end
end
