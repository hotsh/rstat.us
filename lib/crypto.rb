require 'openssl'
require 'rsa'

KeyPair = Struct.new(:public_key, :private_key)

module Crypto
  extend self
  def generate_keypair
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
  def self.make_rsa_keypair(public_key, private_key)
    private_key = generate_key(private_key)
    public_key = generate_key(public_key)

    RSA::KeyPair.new(private_key, public_key)
  end

  private

  def generate_key(key_string)
    return nil unless key_string

    key_string.match /^RSA\.(.*?)\.(.*)$/

    modulus = decode_key($1)
    exponent = decode_key($2)

    RSA::Key.new(modulus, exponent)
  end

  def decode_key(encoded_key_part)
    modulus = Base64::urlsafe_decode64(encoded_key_part)
    modulus.bytes.inject(0) {|num, byte| (num << 8) | byte }
  end
end
