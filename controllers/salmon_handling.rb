class Rstatus
  require 'xml'
  require 'atom'
  require 'digest/sha2'
  require 'rsa'
  require 'openssl'

  # Salmon input
  post '/feeds/:id/salmon' do
    feed = Feed.first :id => params[:id]

    if feed.nil?
      status 404
      return
    end

    body = request.body.read
    xml = XML::Document.string(body, :options => XML::Parser::Options::NOENT)

    envelope = xml.find('/me:env', 
                        'me:http://salmon-protocol.org/ns/magic-env').first

    if envelope.nil?
      status 404
      return
    else
      p body
      data = envelope.find('me:data', 
                           'me:http://salmon-protocol.org/ns/magic-env').first
      data_type = data.attributes["type"]
      if data_type.nil?
        data_type = 'application/atom+xml'
        armored_data_type = ''
      else
        armored_data_type = Base64::urlsafe_encode64(data_type)
      end
      encoding = envelope.find('me:encoding',
                               'me:http://salmon-protocol.org/ns/magic-env').first
      algorithm = envelope.find('me:alg',
                          'me:http://salmon-protocol.org/ns/magic-env').first
      signature = xml.find('me:sig',
                           'me:http://salmon-protocol.org/ns/magic-env').first

      # Parse fields

      if signature.nil?
        # Well, if we cannot verify, we don't accept
        status 404
        return
      else
        p signature.attributes["key_id"]
        signature = signature.content
        signature = Base64::urlsafe_decode64(signature)
        p signature
      end

      if encoding.nil?
        # When the encoding is omitted, use base64url
        # Cite: Magic Envelope Draft Spec Section 3.3
        armored_encoding = ''
        encoding = 'base64url'
      else
        armored_encoding = Base64::urlsafe_encode64(encoding.content)
        encoding = encoding.content.downcase
      end

      if algorithm.nil?
        # When algorithm is omitted, use 'RSA-SHA256'
        # Cite: Magic Envelope Draft Spec Section 3.3
        armored_algorithm = ''
        algorithm = 'rsa-sha256'
      else
        armored_algorithm = Base64::urlsafe_encode64(algorithm.content)
        algorithm = algorithm.content.downcase
      end

      # Retrieve and decode data payload

      if data.nil?
        # Useless to have no data payload
        status 404
        return
      else
        data = data.content
        armored_data = data
        case encoding
        when 'base64url'
          data = Base64::urlsafe_decode64(data)
        else
          # Unsupported data encoding
          status 404
          return
        end
      end

      # Verify data payload

      # Interpret data payload
      doc = XML::Document.string(data)
      thread = doc.find('thr:in-reply-to', 
                        'thr:http://purl.org/syndication/thread/1.0').first
      payload = XML::Reader.string(data)
      atom_entry = OStatus::Entry.new(payload)

      if atom_entry.author.uri.start_with?(url("/"))
        # Is a local user, we can ignore salmon
        status 200
        return
      end

      author = Author.first :remote_url => atom_entry.author.uri
      verify_author = false
      if true || author.nil?
        # This author is unknown to us, we should create a new author

        verify_author = true

        author = Author.new
        author.name = atom_entry.author.portable_contacts.display_name
        puts "Name: #{author.name}"
        author.username = atom_entry.author.name
        puts "Username: #{author.name}"
        author.remote_url = atom_entry.author.uri
        puts "Uri: #{author.remote_url}"
        author.email = atom_entry.author.email
        author.email = nil if author.email == ""
        puts "Email: #{author.email}"
        author.bio = atom_entry.author.portable_contacts.note
        puts "Bio: #{author.bio}"
        avatar_url = atom_entry.author.links.find_all{|l| l.rel.downcase == "avatar"}.first.href
        author.image_url = avatar_url
        puts "Avatar Url: #{author.avatar_url}"

        # Retrieve the user xrd
        remote_host = author.remote_url[/^.*?:\/\/(.*?)\//,1]
        webfinger = "#{author.username}@#{remote_host}"
        puts "Webfinger: #{webfinger}"
        acct = Redfinger.finger(webfinger)

        # Retrieve the feed url for the user
        feed_url = acct.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }

        # Retrieve the public key
        public_key = acct.links.find { |l| l['rel'] == 'magic-public-key' }
        public_key = public_key.href[/^.*?,(.*)$/,1]
        author.public_key = public_key
        puts "Public Key: #{author.public_key}"

        # TODO: key retrieval and verification

      end

      # verify the feed
      verified = false

      # RSA decrypt
      author.public_key.match /^RSA\.(.*?)\.(.*)$/
      modulus = $1
      modulus = Base64::urlsafe_decode64(modulus)
      exponent = $2
      exponent = Base64::urlsafe_decode64(exponent)
      puts "Hmm"
      p modulus
      p exponent
      modulus_bytes = modulus.bytes.count
      modulus = modulus.bytes.inject(0) do |num, byte|
        num <<= 8;
        num |= byte;
      end
      exponent = exponent.bytes.inject(0) do |num, byte|
        num <<= 8;
        num |= byte;
      end
      puts "Modulus: #{modulus} by #{exponent}"
      key = RSA::Key.new(modulus, exponent)
      keypair = RSA::KeyPair.new(nil, key)
      p signature
      p armored_data
      p armored_data_type
      p armored_encoding
      p armored_algorithm
      p plaintext = "#{armored_data}.#{armored_data_type}.#{armored_encoding}.#{armored_algorithm}"
      p plaintext = Digest::SHA2.new(256).digest(plaintext)
      prefix = "\x30\x31\x30\x0d\x06\x09\x60\x86\x48\x01\x65\x03\x04\x02\x01\x05\x00\x04\x20"
      padding_count = modulus_bytes - prefix.bytes.count - plaintext.bytes.count - 3

      padding = ""
      padding_count.times do 
        padding = padding + "\xff"
      end

      emsa = "\x00\x01#{padding}\x00#{prefix}#{plaintext}"
      p emsa
      p keypair.verify(signature, plaintext)
      emsa_signature = keypair.encrypt(signature)
      # Statusnet has a bug in its encryption where it drops the
      # first null byte
      if emsa_signature.getbyte(0) == 1
        emsa_signature = "\x00#{emsa_signature}"
      end
      p emsa_signature
      if emsa_signature == emsa
        puts "VERIFIED"
        verified = true
      else
        puts "NO!"
      end

      # Tear apart emsa
      # 

      # Actually commit the new author
      if verified and verify_author
        puts "Feed"
        # Create a feed for our author
        author.feed = Feed.create(:author => author, 
                                  :remote_url => feed_url)
        author.save
      end

      if not verified
        # Verification has failed
        status 404
        return
      end

      # populate the feed
      author.feed.populate_entries [atom_entry]

      if development?
        puts "Salmon notification"
      end

      if not thread.nil?
        update_url = thread.attributes['href']
        if update_url.start_with?(url("/"))
          # Local update url
          # Retrieve update id
          update_id = update_url[/#{url("\/")}updates\/(.*)$/,1]
          u = author.feed.updates.first :remote_url => atom_entry.url
          u.referral_id = update_id
          u.save
        end
      end
    end
  end
end
